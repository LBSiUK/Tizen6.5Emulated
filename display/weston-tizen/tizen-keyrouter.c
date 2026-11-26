/*
 * tizen-keyrouter.so -- a weston module that advertises the Tizen
 * `tizen_keyrouter` global, so Tizen's DALi/FLUX TV apps get past
 * KeyRouter.InitKeyRouter() on a stock compositor.
 *
 * Why: libdali-extension-tv.so's KeyRouter_Initialize() walks
 * ecore_wl2_display_globals_get() looking for a registry global whose
 * interface name is "tizen_keyrouter" (15 chars, strncmp'd).  A plain
 * weston has no such global, so it logs and returns false, and the app
 * dies with "Failed to initialize KeyRouter" long before it draws.
 *
 * The requests here are all no-ops: the app builds the UI and registers
 * its grab list; we accept it and never route keys.  That is deliberate --
 * first milestone is the real UI on screen, input routing comes later.
 *
 * Build: see build.sh (needs weston-devel + wayland-devel).
 * Use:   weston ... --modules=tizen-keyrouter.so
 */

#include <stdint.h>
#include <wayland-server-core.h>
#include <wayland-server-protocol.h>
#include <libweston/libweston.h>

#include "tizen-keyrouter-server.h"

static void
kr_set_keygrab(struct wl_client *client, struct wl_resource *res,
	       struct wl_resource *surface, uint32_t key, uint32_t mode)
{
	(void)client; (void)res; (void)surface; (void)key; (void)mode;
}

static void
kr_unset_keygrab(struct wl_client *client, struct wl_resource *res,
		 struct wl_resource *surface, uint32_t key)
{
	(void)client; (void)res; (void)surface; (void)key;
}

static void
kr_get_keygrab_status(struct wl_client *client, struct wl_resource *res,
		      struct wl_resource *surface, uint32_t key)
{
	(void)client; (void)res; (void)surface; (void)key;
}

static void
kr_set_keygrab_list(struct wl_client *client, struct wl_resource *res,
		    struct wl_resource *surface, struct wl_array *grab_list)
{
	(void)client; (void)res; (void)surface; (void)grab_list;
}

static void
kr_unset_keygrab_list(struct wl_client *client, struct wl_resource *res,
		      struct wl_resource *surface, struct wl_array *ungrab_list)
{
	(void)client; (void)res; (void)surface; (void)ungrab_list;
}

static void
kr_get_keygrab_list(struct wl_client *client, struct wl_resource *res,
		    struct wl_resource *surface)
{
	(void)client; (void)res; (void)surface;
}

static void
kr_set_register_none_key(struct wl_client *client, struct wl_resource *res,
			 struct wl_resource *surface, uint32_t data)
{
	(void)client; (void)res; (void)surface; (void)data;
}

static void
kr_get_keyregister_status(struct wl_client *client, struct wl_resource *res,
			  uint32_t data)
{
	(void)client; (void)res; (void)data;
}

static void
kr_set_input_config(struct wl_client *client, struct wl_resource *res,
		    struct wl_resource *surface, uint32_t config_mode,
		    uint32_t value)
{
	(void)client; (void)res; (void)surface; (void)config_mode; (void)value;
}

static void
kr_destroy(struct wl_client *client, struct wl_resource *res)
{
	(void)client;
	wl_resource_destroy(res);
}

static const struct tizen_keyrouter_interface kr_impl = {
	.set_keygrab = kr_set_keygrab,
	.unset_keygrab = kr_unset_keygrab,
	.get_keygrab_status = kr_get_keygrab_status,
	.set_keygrab_list = kr_set_keygrab_list,
	.unset_keygrab_list = kr_unset_keygrab_list,
	.get_keygrab_list = kr_get_keygrab_list,
	.set_register_none_key = kr_set_register_none_key,
	.get_keyregister_status = kr_get_keyregister_status,
	.set_input_config = kr_set_input_config,
	.destroy = kr_destroy,
};

static void
kr_bind(struct wl_client *client, void *data, uint32_t version, uint32_t id)
{
	struct wl_resource *res;

	res = wl_resource_create(client, &tizen_keyrouter_interface,
				 (int)(version < 2 ? version : 2), id);
	if (!res) {
		wl_client_post_no_memory(client);
		return;
	}
	wl_resource_set_implementation(res, &kr_impl, NULL, NULL);
}

WL_EXPORT int
wet_module_init(struct weston_compositor *ec, int *argc, char *argv[])
{
	(void)argc; (void)argv;

	if (!wl_global_create(ec->wl_display, &tizen_keyrouter_interface, 2,
			      NULL, kr_bind))
		return -1;
	return 0;
}
