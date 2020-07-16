#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core_const>

#define PLUGIN "[MG] Core"
#define VERSION "1.0"
#define AUTH "Vieni"

new gPrefixMenu[] = "\dMasterGaming\r| \y"
new gPrefixChat[] = "!g[*MG*] !n"

new Array:arrayFrequentMessage
new Array:arrayFrequentMessageSent

new Trie:trieChatCommandPlugin
new Trie:trieChatCommandFunction

new bool:gBlockFreqMessage = false

new gMaxPlayers

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTH)

    register_clcmd("say", "cmdSay")
    register_clcmd("say_team", "cmdSay")

    gMaxPlayers = get_maxplayers()

    register_forward(FM_GetGameDescription, "fwFmGetGameDescription")

    set_task(15.0, "sendFrequentMessage")
}

public plugin_natives()
{
    arrayFrequentMessage = ArrayCreate(32)
    arrayFrequentMessageSent = ArrayCreate(1)

    trieChatCommandPlugin = TrieCreate()
    trieChatCommandFunction = TrieCreate()

    register_native("mg_core_serverid_get", "native_core_serverid_get")
    register_native("ng_core_gamemode_get", "native_core_gamemode_get")
    register_native("mg_core_menu_prefix_get", "native_core_menu_prefix_get")
    register_native("mg_core_menu_title_create", "native_core_menu_title_create")
    register_native("mg_core_chat_prefix_get", "native_core_chat_prefix_get")
    register_native("mg_core_chatmessage_print", "native_core_chatmessage_print")
    register_native("mg_core_chatmessage_freq_reg", "native_core_chatmessage_freq_reg")
    register_native("mg_core_chatmessage_freq_block", "native_core_chatmessage_freq_block")
    register_native("mg_core_command_reg", "native_core_command_reg")
    register_native("mg_core_command_del", "native_core_command_del")
}

public cmdSay(id)
{
    static lMessage[192]

    read_args(lMessage, charsmax(lMessage))
    remove_quotes(lMessage)

    if(!lMessage[0] || lMessage[0] == '@' || lMessage[0] == '#')
		return PLUGIN_HANDLED

    if(lMessage[0] == '/' || lMessage[0] == '!')
	{
        if(TrieKeyExists(trieChatCommandPlugin, lMessage[1]))
        {
            new lPluginFileName[99], lFunction[50]

            TrieGetString(trieChatCommandPlugin, lMessage[1], lPluginFileName, charsmax(lPluginFileName))
            TrieGetString(trieChatCommandFunction, lMessage[1], lFunction, charsmax(lFunction))

            triggerFunction(id, lPluginFileName, lFunction)
            return PLUGIN_HANDLED
        }
        
        new lCommand[22]

        copy(lCommand, charsmax(lCommand), lMessage)
		
        lMessage[0] = EOS

        formatex(lMessage, charsmax(lMessage), "%s%L", gPrefixChat, id, "CHAT_NOSUCHCOMMAND", lCommand)
        print_chatmessage(id, lMessage)

        return PLUGIN_HANDLED
	}

    return PLUGIN_CONTINUE
}

public sendFrequentMessage()
{
    if(gBlockFreqMessage)
    {
        gBlockFreqMessage = false
        set_task(15.0, "sendFrequentMessage")
        return
    }

    new lArrayId
    new lArraySize = ArraySize(arrayFrequentMessage)

    if(!lArraySize)
    {
        set_task(15.0, "sendFrequentMessage")
        return
    }

    do
    {
        lArrayId = random_num(0, lArraySize-1)
    }
    while(ArrayFindValue(arrayFrequentMessageSent, lArrayId) && ArraySize(arrayFrequentMessageSent) < lArraySize)

    ArrayPushCell(arrayFrequentMessageSent, lArrayId)

    new lMessage[192], lMessageLang[32]

    ArrayGetString(arrayFrequentMessage, lArrayId, lMessageLang, charsmax(lMessageLang))

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_connected(i))
            continue

        lMessage[0] = EOS
        formatex(lMessage, charsmax(lMessage), "%s%L", gPrefixChat, i, lMessageLang)
        print_chatmessage(i, lMessage)
    }

    if(ArraySize(arrayFrequentMessageSent) > 4)
    {
        ArrayDeleteItem(arrayFrequentMessageSent, 0)
    }

    set_task(15.0, "sendFrequentMessage")
}

public native_core_serverid_get(plugin_id, param_num)
{
    return MG_SERVER_CURRENT
}

public native_core_gamemode_get(plugin_id, param_num)
{
    new len = get_param(2)

    set_string(1, MG_SERVER_GAMEMODE, len)

    return true
}

public native_core_menu_prefix_get(plugin_id, param_num)
{
    static len
    len = get_param(2)

    set_string(1, gPrefixMenu, len)
    return true
}

public native_core_menu_title_create(plugin_id, param_num)
{
    static id, lMenuText[30], lLen, lMenuTitle[60], lVersion
    id = get_param(1)
    lVersion = get_param(5)

    get_string(2, lMenuText, charsmax(lMenuText))

    lMenuTitle[0] = EOS
    
    formatex(lMenuTitle, charsmax(lMenuTitle), "\r[%s%L*\y%s\r]^n", gPrefixMenu, id, lMenuText, lVersion ? MG_SERVER_VERSION:"")

    lLen = get_param(4)
    set_string(3, lMenuTitle, lLen)

    return strlen(lMenuTitle)
}

public native_core_chat_prefix_get(plugin_id, param_num)
{
    new lLen = get_param(2)

    set_string(1, gPrefixChat, lLen)

    return true
}

public native_core_chatmessage_print(plugin_id, param_num)
{
    static lType, lInput[191]

    lType = get_param(2)

    switch(lType)
    {
        case MG_CM_PLAYERTOCHAT:
        {
            get_string(4, lInput, charsmax(lInput))
            print_chatmessage(0, lInput)
        }
        case MG_CM_FIX:
        {
            new id = get_param(1)
            new lChatTeam = get_param(3)
            
            vdformat(lInput, charsmax(lInput), 4, 5)
            format(lInput, charsmax(lInput), "%s%s", gPrefixChat, lInput)

            print_chatmessage(id, lInput, CsTeams:lChatTeam)
        }
        case MG_CM_FIXFREQ:
        {
            new id = get_param(1)
            new CsTeams:lChatTeam = CsTeams:get_param(3)
            
            gBlockFreqMessage = true

            vdformat(lInput, charsmax(lInput), 4, 5)
            format(lInput, charsmax(lInput), "%s%s", gPrefixChat, lInput)

            print_chatmessage(id, lInput, CsTeams:lChatTeam)
        }
        case MG_CM_NORMAL:
        {
            new id = get_param(1)
            new lChatTeam = get_param(3)
            
            vdformat(lInput, charsmax(lInput), 4, 5)
            print_chatmessage(id, lInput, CsTeams:lChatTeam)
        }
        case MG_CM_NORMALFREQ:
        {
            new id = get_param(1)
            new lChatTeam = get_param(3)

            gBlockFreqMessage = true

            vdformat(lInput, charsmax(lInput), 4, 5)
            print_chatmessage(id, lInput, CsTeams:lChatTeam)
        }
    }
    return true
}

public native_core_chatmessage_freq_reg(plugin_id, param_num)
{
    new lMessageLang[32]
    get_string(1, lMessageLang, charsmax(lMessageLang))

    if(ArrayFindString(arrayFrequentMessage, lMessageLang))
    {
        log_amx("[REGISTERFREQUENTMESSAGE] Message's already registered!")

        return false
    }

    ArrayPushString(arrayFrequentMessage, lMessageLang)

    return true
}

public native_core_chatmessage_freq_block(plugin_id, param_num)
{
    gBlockFreqMessage = true
    
    return true
}

public native_core_command_reg(plugin_id, param_num)
{
    new lCommand[22], lFunction[50], lPluginFileName[99]

    get_string(1, lCommand, charsmax(lCommand))
    get_string(2, lFunction, charsmax(lFunction))

    get_plugin(plugin_id, lPluginFileName, charsmax(lPluginFileName))

    TrieSetString(trieChatCommandPlugin, lCommand, lPluginFileName)
    TrieSetString(trieChatCommandFunction, lCommand, lFunction)

    return true
}

public native_core_command_del(plugin_id, param_num)
{
    new lCommand[20]

    get_string(1, lCommand, charsmax(lCommand))

    return (TrieDeleteKey(trieChatCommandPlugin, lCommand) && TrieDeleteKey(trieChatCommandFunction, lCommand))
}

public client_command(id)
{
    static lCommand[22]
    read_argv(0, lCommand, charsmax(lCommand))

    if(TrieKeyExists(trieChatCommandPlugin, lCommand))
    {
        new lPluginFileName[99], lFunction[50]

        TrieGetString(trieChatCommandPlugin, lCommand, lPluginFileName, charsmax(lPluginFileName))
        TrieGetString(trieChatCommandFunction, lCommand, lFunction, charsmax(lFunction))

        triggerFunction(id, lPluginFileName, lFunction)
        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}

public fwFmGetGameDescription()
{
   	forward_return(FMV_STRING, MG_SERVER_GAMEMODE)
	
	return FMRES_SUPERCEDE
}

triggerFunction(id, const pluginFileName[], const function[])
{
    callfunc_begin(function, pluginFileName)
    callfunc_push_int(id)
    callfunc_end()

