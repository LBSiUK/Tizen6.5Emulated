implemented = set("""package_info_create package_info_clone package_info_destroy
package_info_get_package package_info_get_label package_info_get_type
package_info_get_version package_info_get_icon package_info_get_path
package_info_get_tep_name package_manager_get_package_info
package_manager_foreach_package_info package_info_foreach_app_from_package""".split())
names = [l.strip() for l in open('/tmp/pkgcapi_funcs.txt') if l.strip()]
rest = [n for n in names if n not in implemented]
missing = implemented - set(names)
assert not missing, f"implemented but not exported: {missing}"
with open('/tmp/pkgcapi_stub2.c','w') as f:
    f.write(open('/tmp/pkgcapi_stub2_core.c').read())
    f.write('\n/* remainder: service-unavailable */\n')
    for n in rest:
        f.write(f'__attribute__((visibility("default"))) int {n}() {{ return -1; }}\n')
print(f"core {len(implemented)} + blanket {len(rest)} = {len(names)}")
