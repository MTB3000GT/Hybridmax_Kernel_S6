/* Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/device.h>
#include <linux/delay.h>
#include <linux/slab.h>
#include <linux/termios.h>
#include <linux/debugfs.h>
#include <linux/bitops.h>
#include <linux/termios.h>
#include <mach/usb_bridge.h>
#include <mach/usb_gadget_xport.h>

#ifdef CONFIG_OF
#include <linux/of_device.h>
#include <linux/of_gpio.h>
#endif

/* from cdc-acm.h */
#define ACM_CTRL_RTS		(1 << 1)	/* unused with full duplex */
#define ACM_CTRL_DTR		(1 << 0)	/* host is ready for data r/w */
#define ACM_CTRL_OVERRUN	(1 << 6)
#define ACM_CTRL_PARITY		(1 << 5)
#define ACM_CTRL_FRAMING	(1 << 4)
#define ACM_CTRL_RI		(1 << 3)
#define ACM_CTRL_BRK		(1 << 2)
#define ACM_CTRL_DSR		(1 << 1)
#define ACM_CTRL_DCD		(1 << 0)


static unsigned int	no_ctrl_ports;

static const char	*ctrl_bridge_names[] = {
	"dun_ctrl_hsic0",
	"rmnet_ctrl_hsic0"
};

#define CTRL_BRIDGE_NAME_MAX_LEN	20
#define READ_BUF_LEN			1024

#define CH_OPENED 0
#define CH_READY 1

struct gctrl_port {
	/* port */
	unsigned		port_num;

	/* gadget */
	spinlock_t		port_lock;
	void			*port_usb;

	/* work queue*/
	struct workqueue_struct	*wq;
	struct work_struct	connect_w;
	struct work_struct	disconnect_w;

	enum gadget_type	gtype;

	/*ctrl pkt response cb*/
	int (*send_cpkt_response)(void *g, void *buf, size_t len);

	struct bridge		brdg;

	/* bridge status */
	unsigned long		bridge_sts;

	/* control bits */
	unsigned		cbits_tomodem;
	unsigned		cbits_tohost;

	/* counters */
	unsigned long		to_modem;
	unsigned long		to_host;
	unsigned long		drp_cpkt_cnt;
};

static struct {
	struct gctrl_port	*port;
	struct platform_driver	pdrv;
	char			port_name[BRIDGE_NAME_MAX_LEN];
} gctrl_ports[NUM_PORTS];

static int ghsic_ctrl_receive(void *dev, void *buf, size_t actual)
{
	struct gctrl_port	*port = dev;
	int retval = 0;

	pr_debug("usb:(hsic) %s: read complete bytes read: %ld\n",
			__func__, actual);

	/* send it to USB here */
	if (port && port->send_cpkt_response) {
		retval = port->send_cpkt_response(port->port_usb, buf, actual);
		port->to_host++;
	}

	return retval;
}

static void
ghsic_send_cbits_tomodem(void *gptr, u8 portno, int cbits)
{
	struct gctrl_port	*port;

	pr_debug("usb:(hsic) %s: portno:%d\n", __func__, portno);

	if (portno >= no_ctrl_ports || !gptr) {
		pr_debug("%s: Invalid portno#%d\n", __func__, portno);
		return;
	}

	port = gctrl_ports[portno].port;
	if (!port) {
		pr_debug("%s: port is null\n", __func__);
		return;
	}

	pr_debug("usb:(hsic) %s: port:%p\n", __func__, port);

	pr_debug("usb:(hsic) %s: cbits:%d, cbits_tomodem=%d\n", __func__, cbits, port->cbits_tomodem);
	if (cbits == port->cbits_tomodem)
		return;

	port->cbits_tomodem = cbits;

	pr_debug("usb:(hsic) %s: test bit (%ld)\n", __func__, port->bridge_sts);
	if (!test_bit(CH_OPENED, &port->bridge_sts))
		return;

	pr_debug("usb:(hsic) %s: ctrl_tomodem:%d\n", __func__, cbits);

	ctrl_bridge_set_cbits(port->brdg.ch_id, cbits);
}

static void ghsic_ctrl_connect_w(struct work_struct *w)
{
	struct gserial		*gser = NULL;
	struct gctrl_port	*port =
			container_of(w, struct gctrl_port, connect_w);
	unsigned long		flags;
	int			retval;
	unsigned		cbits;

	pr_info("usb:(hsic) %s\n", __func__);
	if (!port || !test_bit(CH_READY, &port->bridge_sts)){
		pr_info("usb:(hsic) %s: NOT READY!!\n", __func__);	
		return;
	}

	pr_info("usb:(hsic) %s: port:%p, name=%s\n", __func__, port, port->brdg.name);

	retval = ctrl_bridge_open(&port->brdg);
	if (retval) {
		pr_info("%s: ctrl bridge open failed :%d\n", __func__, retval);
		return;
	}

	pr_debug("usb:(hsic) %s : set bit - CH_OPENED(sts=%ld)\n", __func__, port->bridge_sts);
	spin_lock_irqsave(&port->port_lock, flags);
	if (!port->port_usb) {
		ctrl_bridge_close(port->brdg.ch_id);
		spin_unlock_irqrestore(&port->port_lock, flags);
		return;
	}

	set_bit(CH_OPENED, &port->bridge_sts);

	if (port->cbits_tomodem)
		ctrl_bridge_set_cbits(port->brdg.ch_id, port->cbits_tomodem);

	spin_unlock_irqrestore(&port->port_lock, flags);

	pr_debug("usb:(hsic) %s : result (sts=%ld)\n", __func__, port->bridge_sts);
	cbits = ctrl_bridge_get_cbits_tohost(port->brdg.ch_id);

	if (port->gtype == USB_GADGET_SERIAL && (cbits & ACM_CTRL_DCD)) {
		gser = (struct gserial *)(port->port_usb);
		if (gser && gser->connect)
			gser->connect(gser);
		return;
	}

}

int ghsic_ctrl_connect(void *gptr, int port_num)
{
	struct gctrl_port	*port;
	struct gserial		*gser;
	unsigned long		flags;

	pr_debug("usb:(hsic) %s: port#%d\n", __func__, port_num);

	if (port_num > no_ctrl_ports || !gptr) {
		pr_err("%s: invalid portno#%d\n", __func__, port_num);
		return -ENODEV;
	}

	port = gctrl_ports[port_num].port;
	if (!port) {
		pr_err("%s: port is null\n", __func__);
		return -ENODEV;
	}

	pr_debug("usb:(hsic) %s: port->gtype#%d\n", __func__, port->gtype);
	spin_lock_irqsave(&port->port_lock, flags);
	if (port->gtype == USB_GADGET_SERIAL) {
		gser = gptr;
		gser->notify_modem = ghsic_send_cbits_tomodem;
	}

	port->port_usb = gptr;
	port->to_host = 0;
	port->to_modem = 0;
	port->drp_cpkt_cnt = 0;
	spin_unlock_irqrestore(&port->port_lock, flags);

	queue_work(port->wq, &port->connect_w);

	return 0;
}

static void gctrl_disconnect_w(struct work_struct *w)
{
	struct gctrl_port	*port =
			container_of(w, struct gctrl_port, disconnect_w);

	pr_debug("usb:(hsic) %s\n", __func__);

	if (!test_bit(CH_OPENED, &port->bridge_sts))
		return;

	/* send the dtr zero */
	pr_debug("usb:(hsic) %s Clear CH_OPENED\n", __func__);
	ctrl_bridge_close(port->brdg.ch_id);
	clear_bit(CH_OPENED, &port->bridge_sts);
}

void ghsic_ctrl_disconnect(void *gptr, int port_num)
{
	struct gctrl_port	*port;
	struct gserial		*gser = NULL;
	unsigned long		flags;

	pr_debug("usb:(hsic) %s: port#%d\n", __func__, port_num);

	port = gctrl_ports[port_num].port;

	if (port_num > no_ctrl_ports) {
		pr_err("%s: invalid portno#%d\n", __func__, port_num);
		return;
	}

	if (!gptr || !port) {
		pr_err("%s: grmnet port is null\n", __func__);
		return;
	}

	if (port->gtype == USB_GADGET_SERIAL)
			gser = (struct gserial *)gptr;

	spin_lock_irqsave(&port->port_lock, flags);

	if (gser)
		gser->notify_modem = 0;
	port->cbits_tomodem = 0;
	port->port_usb = 0;
	port->send_cpkt_response = 0;
	spin_unlock_irqrestore(&port->port_lock, flags);

	queue_work(port->wq, &port->disconnect_w);
}

static void ghsic_ctrl_status(void *ctxt, unsigned int ctrl_bits)
{
	struct gctrl_port	*port = ctxt;
	struct gserial		*gser;

	pr_debug("usb:(hsic) %s - input control lines: dcd%c dsr%c break%c "
		 "ring%c framing%c parity%c overrun%c\n", __func__,
		 ctrl_bits & ACM_CTRL_DCD ? '+' : '-',
		 ctrl_bits & ACM_CTRL_DSR ? '+' : '-',
		 ctrl_bits & ACM_CTRL_BRK ? '+' : '-',
		 ctrl_bits & ACM_CTRL_RI  ? '+' : '-',
		 ctrl_bits & ACM_CTRL_FRAMING ? '+' : '-',
		 ctrl_bits & ACM_CTRL_PARITY ? '+' : '-',
		 ctrl_bits & ACM_CTRL_OVERRUN ? '+' : '-');

	port->cbits_tohost = ctrl_bits;
	gser = port->port_usb;
	if (gser && gser->send_modem_ctrl_bits)
		gser->send_modem_ctrl_bits(gser, ctrl_bits);
}

static int ghsic_ctrl_get_port_id(const char *pdev_name)
{
	struct gctrl_port	*port;
	int			i;

	for (i = 0; i < no_ctrl_ports; i++) {
		port = gctrl_ports[i].port;
		if (!strncmp(port->brdg.name, pdev_name, BRIDGE_NAME_MAX_LEN))
			return i;
	}

	return -EINVAL;
}

static int ghsic_ctrl_probe(struct platform_device *pdev)
{
	struct gctrl_port	*port;
	unsigned long		flags;
	int			id;

	pr_info("usb:(hsic) %s: name:%s , no_ctrl_ports=%d\n",
					__func__, pdev->name, no_ctrl_ports);

/*	if (pdev->id >= no_ctrl_ports) {
		pr_info("%s: invalid port: %d\n", __func__, pdev->id);
		return -EINVAL;
	} */

	id = ghsic_ctrl_get_port_id(pdev->name);
	if (id < 0 || id >= no_ctrl_ports) {
		pr_err("%s: invalid port: %d\n", __func__, id);
		return -EINVAL;
	}

	port = gctrl_ports[id].port;//	port = gctrl_ports[pdev->id].port;
	set_bit(CH_READY, &port->bridge_sts);
	pr_info("usb:(hsic) %s :  set bit - CH_READY (sts=%ld)\n", __func__, port->bridge_sts);

	/* if usb is online, start read */
	spin_lock_irqsave(&port->port_lock, flags);
	if (port->port_usb)
		queue_work(port->wq, &port->connect_w);
	spin_unlock_irqrestore(&port->port_lock, flags);

	return 0;
}

static int ghsic_ctrl_remove(struct platform_device *pdev)
{
	struct gctrl_port	*port;
	struct gserial		*gser = NULL;
	unsigned long		flags;
	int			id;

	pr_debug("usb:(hsic) %s: name:%s\n", __func__, pdev->name);

/*	if (pdev->id >= no_ctrl_ports) {
		pr_err("%s: invalid port: %d\n", __func__, pdev->id);
		return -EINVAL;
	} */
	id = ghsic_ctrl_get_port_id(pdev->name);
	if (id < 0 || id >= no_ctrl_ports) {
		pr_err("%s: invalid port: %d\n", __func__, id);
		return -EINVAL;
	}
	port = gctrl_ports[id].port;//	port = gctrl_ports[pdev->id].port;

	spin_lock_irqsave(&port->port_lock, flags);
	if (!port->port_usb) {
		spin_unlock_irqrestore(&port->port_lock, flags);
		goto not_ready;
	}

	if (port->gtype == USB_GADGET_SERIAL)
		gser = port->port_usb;

	port->cbits_tohost = 0;
	spin_unlock_irqrestore(&port->port_lock, flags);

	if (gser && gser->disconnect)
		gser->disconnect(gser);

	ctrl_bridge_close(port->brdg.ch_id);

	pr_debug("usb:(hsic) %s Clear CH_OPENED \n", __func__);
	clear_bit(CH_OPENED, &port->bridge_sts);
not_ready:
	pr_debug("usb:(hsic) %s Clear CH_READY \n", __func__);
	clear_bit(CH_READY, &port->bridge_sts);

	return 0;
}

static void ghsic_ctrl_port_free(int portno)
{
	struct gctrl_port	*port = gctrl_ports[portno].port;
	struct platform_driver	*pdrv = &gctrl_ports[portno].pdrv;

	destroy_workqueue(port->wq);
	kfree(port);

	if (pdrv)
		platform_driver_unregister(pdrv);
}


#ifdef CONFIG_OF
static const struct of_device_id usb_hsic_ctrl_bridge_dt_ids[] = {
	{ .compatible = "samsung,acm_ctrl_mdm_bridge",
	},
	{ },
};
MODULE_DEVICE_TABLE(of, usb_hsic_ctrl_bridge_dt_ids);
#endif

static int gctrl_port_alloc(int portno, enum gadget_type gtype)
{
	struct gctrl_port	*port;
	struct platform_driver	*pdrv;
	char			*name;
	int ret;

	port = kzalloc(sizeof(struct gctrl_port), GFP_KERNEL);
	if (!port)
		return -ENOMEM;

	name = gctrl_ports[portno].port_name;
	port->wq = create_freezable_workqueue(name);
	if (!port->wq) {
		pr_info("usb:(hsic) %s: Unable to create workqueue:%s\n",
			__func__, ctrl_bridge_names[portno]);
		return -ENOMEM;
	}

	port->port_num = portno;
	port->gtype = gtype;

	spin_lock_init(&port->port_lock);

	INIT_WORK(&port->connect_w, ghsic_ctrl_connect_w);
	INIT_WORK(&port->disconnect_w, gctrl_disconnect_w);

	port->brdg.name = name;
	port->brdg.ctx = port;
	port->brdg.ops.send_pkt = ghsic_ctrl_receive;
	if (port->gtype == USB_GADGET_SERIAL)
		port->brdg.ops.send_cbits = ghsic_ctrl_status;
	gctrl_ports[portno].port = port;

	pdrv = &gctrl_ports[portno].pdrv;
	pdrv->probe = ghsic_ctrl_probe;
	pdrv->remove = ghsic_ctrl_remove;
	pdrv->driver.name = name;
	pdrv->driver.owner = THIS_MODULE;
#ifdef CONFIG_OF
	pdrv->driver.of_match_table	= of_match_ptr(usb_hsic_ctrl_bridge_dt_ids);
#endif

	ret = platform_driver_register(pdrv);

	pr_info("usb:(hsic) %s:(%d) port:%p portno:%d\n", __func__, ret, port, portno);

	return 0;
}

/*portname will be used to find the bridge channel index*/
void ghsic_ctrl_set_port_name(const char *name, const char *xport_type)
{
	static unsigned int port_num;

	pr_info("usb:(hsic) %s \n", __func__);

	if (port_num >= NUM_PORTS) {
		pr_err("%s: setting xport name for invalid port num %d\n",
				__func__, port_num);
		return;
	}

	/*if no xport name is passed set it to xport type e.g. hsic*/
	if (!name)
		strlcpy(gctrl_ports[port_num].port_name, xport_type,
				BRIDGE_NAME_MAX_LEN);
	else
		strlcpy(gctrl_ports[port_num].port_name, name,
				BRIDGE_NAME_MAX_LEN);

	/*append _ctrl to get ctrl bridge name e.g. serial_hsic_ctrl*/
	strlcat(gctrl_ports[port_num].port_name, "_ctrl", BRIDGE_NAME_MAX_LEN);

	port_num++;
}

int ghsic_ctrl_setup(unsigned int num_ports, enum gadget_type gtype)
{
	int		first_port_id = no_ctrl_ports;
	int		total_num_ports = num_ports + no_ctrl_ports;
	int		i;
	int		ret = 0;

	pr_info("usb:(hsic) %s \n", __func__);


	if (!num_ports || total_num_ports > NUM_PORTS) {
		pr_info("usb:(hsic) %s: Invalid num of ports count:%d\n",
				__func__, num_ports);
		return -EINVAL;
	}

	pr_info("usb:(hsic) %s: requested ports:%d\n", __func__, num_ports);

	for (i = first_port_id; i < (first_port_id + num_ports); i++) {

		/*probe can be called while port_alloc,so update no_ctrl_ports*/
		no_ctrl_ports++;
		ret = gctrl_port_alloc(i, gtype);
		if (ret) {
			no_ctrl_ports--;
			pr_info("usb:(hsic) %s: Unable to alloc port:%d\n", __func__, i);
			goto free_ports;
		}
	}

	return first_port_id;

free_ports:
	for (i = first_port_id; i < no_ctrl_ports; i++)
		ghsic_ctrl_port_free(i);
		no_ctrl_ports = first_port_id;
	return ret;
}

#if defined(CONFIG_DEBUG_FS)
#define DEBUG_BUF_SIZE	1024
static ssize_t gctrl_read_stats(struct file *file, char __user *ubuf,
		size_t count, loff_t *ppos)
{
	struct gctrl_port	*port;
	struct platform_driver	*pdrv;
	char			*buf;
	unsigned long		flags;
	int			ret;
	int			i;
	int			temp = 0;

	buf = kzalloc(sizeof(char) * DEBUG_BUF_SIZE, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	for (i = 0; i < no_ctrl_ports; i++) {
		port = gctrl_ports[i].port;
		if (!port)
			continue;
		pdrv = &gctrl_ports[i].pdrv;
		spin_lock_irqsave(&port->port_lock, flags);

		temp += scnprintf(buf + temp, DEBUG_BUF_SIZE - temp,
				"\nName:        %s\n"
				"#PORT:%d port: %p\n"
				"to_usbhost:    %lu\n"
				"to_modem:      %lu\n"
				"cpkt_drp_cnt:  %lu\n"
				"DTR:           %s\n"
				"ch_open:       %d\n"
				"ch_ready:      %d\n",
				pdrv->driver.name,
				i, port,
				port->to_host, port->to_modem,
				port->drp_cpkt_cnt,
				port->cbits_tomodem ? "HIGH" : "LOW",
				test_bit(CH_OPENED, &port->bridge_sts),
				test_bit(CH_READY, &port->bridge_sts));

		spin_unlock_irqrestore(&port->port_lock, flags);
	}

	ret = simple_read_from_buffer(ubuf, count, ppos, buf, temp);

	kfree(buf);

	return ret;
}

static ssize_t gctrl_reset_stats(struct file *file,
	const char __user *buf, size_t count, loff_t *ppos)
{
	struct gctrl_port	*port;
	int			i;
	unsigned long		flags;

	for (i = 0; i < no_ctrl_ports; i++) {
		port = gctrl_ports[i].port;
		if (!port)
			continue;

		spin_lock_irqsave(&port->port_lock, flags);
		port->to_host = 0;
		port->to_modem = 0;
		port->drp_cpkt_cnt = 0;
		spin_unlock_irqrestore(&port->port_lock, flags);
	}
	return count;
}

const struct file_operations gctrl_stats_ops = {
	.read = gctrl_read_stats,
	.write = gctrl_reset_stats,
};

struct dentry	*gctrl_dent;
struct dentry	*gctrl_dfile;
static void gctrl_debugfs_init(void)
{
	gctrl_dent = debugfs_create_dir("ghsic_ctrl_xport", 0);
	if (IS_ERR(gctrl_dent))
		return;

	gctrl_dfile =
		debugfs_create_file("status", 0444, gctrl_dent, 0,
			&gctrl_stats_ops);
	if (!gctrl_dfile || IS_ERR(gctrl_dfile))
		debugfs_remove(gctrl_dent);
}

static void gctrl_debugfs_exit(void)
{
	debugfs_remove(gctrl_dfile);
	debugfs_remove(gctrl_dent);
}

#else
static void gctrl_debugfs_init(void) { }
static void gctrl_debugfs_exit(void) { }
#endif

static int __init gctrl_init(void)
{
	gctrl_debugfs_init();

	return 0;
}
module_init(gctrl_init);

static void __exit gctrl_exit(void)
{
	gctrl_debugfs_exit();
}
module_exit(gctrl_exit);
MODULE_DESCRIPTION("hsic control xport driver");
MODULE_LICENSE("GPL v2");
