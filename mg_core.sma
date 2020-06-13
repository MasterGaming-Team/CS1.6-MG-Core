#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUGIN "[MG] Core"
#define VERSION "1.0"
#define AUTH "Vieni"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTH)

    register_forward(FM_GetGameDescription, "fwFmGetGameDescription")
}

public plugin_natives()
{
    register_native("mg_core_serverid_get", "native_core_serverid_get")
    register_native("ng_core_gamemode_get", "native_core_gamemode_get")
}

public native_core_get_serverid(plugin_id, param_num)
{
    return MG_SERVER_ZOMBIEINSANITY
}

public native_core_gamemode_get(plugin_id, param_num)
{
    new len = get_param(2)

    set_string(1, MG_SERVER_GAMEMODE, len)

    return true
}

public fwFmGetGameDescription(
{
   	forward_return(FMV_STRING, gGamemodeName)
	
	return FMRES_SUPERCEDE
)