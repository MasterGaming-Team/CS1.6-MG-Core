#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core_const>

#define PLUGIN "[MG] Core"
#define VERSION "1.0"
#define AUTH "Vieni"

new gPrefixMenu[] = "\d*MG* \r| \y"
new gPrefixChat[] = "!g[*MG*] !n"

new Array:arrayFrequentMessage
new ArraY:arrayFrequentMessageSent

new Trie:trieChatCommands

new bool:gBlockFreqMessage = false

new gMsgTeamInfo, gMsgSayText

new gMaxPlayers

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTH)

    register_clcmd("say", "cmdSay")
    register_clcmd("say_team", "cmdSayTeam")

    gMsgTeamInfo = get_user_msgid("TeamInfo")
    gMsgSayText = get_user_msgid("SayText")

    gMaxPlayers = get_maxplayers()

    register_forward(FM_GetGameDescription, "fwFmGetGameDescription")

    set_task(15.0, "sendFrequentMessage")
}

public plugin_natives()
{
    arrayFrequentMessage = ArrayCreate(32)
    arrayFrequentMessageSent = ArrayCreate(1)

    trieChatCommands = TrieCreate()

    register_native("mg_core_serverid_get", "native_core_serverid_get")
    register_native("ng_core_gamemode_get", "native_core_gamemode_get")
    register_native("mg_core_menu_prefix_get", "native_core_menu_prefix_get")
    register_native("mg_core_menu_title_create", "native_core_menu_title_create")
    register_native("mg_core_integer_to_formal", "mg_core_integer_to_formal")
    register_native("mg_core_chat_prefix_get", "native_core_chat_prefix_get")
    register_native("mg_core_chatmessage_print", "native_core_chatmessage_print")
    register_native("mg_core_command_reg", "native_core_command_reg")
    register_native("mg_core_command_del", "native_core_command_del")
    register_native("mg_core_message_freq_reg", "native_core_message_freq_reg")
    register_native("mg_core_message_freq_block", "native_core_message_freq_block")
}

public cmdSay(id)
{
    static lMessage[192]

	read_args(lMessage, charsmax(lMessage))
	remove_quotes(lMessage)

	if(!lMessage[0] || lMessage[0] == '@' || lMessage[0] == '#')
		return PLUGIN_HANDLED

    if(TrieKeyExists(trieChatCommands, lMessage))
        return PLUGIN_CONTINUE
	
	if(message[0] == '/' || message[0] == '!')
	{
		copy(command, charsmax(command), message)
		
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_NOSUCHCOMMAND", command)
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

    do
    {
        lArrayId = random_num(0, lArraySize-1)
    }
    while(ArrayFindValue(arrayFrequentMessageSent, lArrayId))

    ArrayPushCell(arrayFrequentMessageSent, lArrayId)

    new lMessage[192], lMessageLang[32]

    ArrayGetString(arrayFrequentMessage, lArrayId, lMessageLang, charsmax(lMessageLang))

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_connected(i))
            continue

        lMessage[0] = EOS
        formatex(lMessage, charsmax(lMesage), "%s%L", gPrefixChat, i, lMessageLang)
        printChatMessage(i, lMessage)
    }

    if(ArraySize(arrayFrequentMessageSent) > 4)
    {
        ArrayDeleteItem(arrayFrequentMessageSent, 0)
    }

    set_task(15.0, "sendFrequentMessage")
}

public native_core_message_freq_block(plugin_id, param_num)
{
    gBlockFreqMessage = true
    
    return true
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

public native_core_menu_prefix_get(plugin_id, param_num)
{
    static len
    len = get_param(2)

    set_string(1, gPrefixMenu, len)
    return true
}

public native_core_menu_title_create(plugin_id, param_num)
{
    static id, lMenuText[30], lLen, lVersion, lMenuTitle[60]
    id = get_param(1)
    lLen = get_param(3)
    lVersion = get_param(4)

    get_string(2, lMenuText, lLen)

    lMenuTitle[0] = EOS
    
    formatex(lMenuTitle, charsmax(lMenuTitle), "\r[%s%L*\y%s\r]", gPrefixMenu, id, lMenuText, lVersion ? MG_SERVER_VERSION:"")

    return lMenuTitle
}

public native_core_integer_to_formal(plugin_id, param_num)
{
    static lInput, lLeft[5], lRight[15], lText[20]

    lInput = get_param(1)

    num_to_str(lInput, lText, charsmax(lText))
	
    if(lInput > 999)
    {	
        if(lInput>= 1000 && lInput <= 9999)
            split(lText, lLeft, charsmax(lLeft), lRight, charsmax(lRight), "")
        else if(lInput >= 10000 && lInput <= 99999)
            split(lText, lLeft, charsmax(lLeft), lRight, charsmax(lRight), "")
        else if(lInput >= 100000 && lInput <= 999999)
            split(lText, lLeft, charsmax(lLeft), lRight, charsmax(lRight), "")
        else if(lInput >= 1000000 && lInput <= 9999999)
            split(lText, lLeft, charsmax(lLeft), lRight, charsmax(lRight), "")
			
        formatex(lText, 11, "%s.%s", lLeft, lRight)
		
        if(lInput > 999999)
        {
            split(lText, lLeft, 1, lRight, 11, "")
            formatex(lText, 11, "%s.%s", lLeft, lRight)
        }
    }

    return lText
}

public native_core_chat_prefix_get(plugin_id, param_num)
{
    return gPrefixChat
}

public native_core_chatmessage_print(plugin_id, param_num)
{
    static id, lInput[191], lChatTeam[20]

    id = get_param(1)
    get_string(2, lInput, charsmax(lInput))
    get_string(3, lChatTeam, charsmax(lChatTeam))

    printChatMessage(id, lInput, lChatTeam)
}

public native_core_command_reg(plugin_id, param_num)
{
    new lCommand[20]

    get_string(1, lCommand, charsmax(lCommand))

    TrieSetCell(trieChatCommands, lCommand, 69, false)

    return true
}

public native_core_command_del(plugin_id, param_num)
{
    new lCommand[20]

    get_string(1, lCommand, charsmax(lCommand))

    TrieDeleteKey(trieChatCommands, lCommand)

    return true
}

public native_core_message_reg(plugin_id, param_num)
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

public fwFmGetGameDescription()
{
   	forward_return(FMV_STRING, MG_SERVER_GAMEMODE)
	
	return FMRES_SUPERCEDE
}

stock printChatMessage(id, input, chatTeam[] = "U")
{
    static lPlayerTeam[20]

    replace_all(input, 190, "%", "%%")

    if(id)
	{
        if(lChatTeam[0] != "U")
		{
			get_user_team(id, lPlayerTeam, charsmax(lPlayerTeam))
					
			message_begin(MSG_ONE_UNRELIABLE, gMsgTeamInfo, _, id)
			write_byte(id)
			write_string(lChatTeam)
			message_end()
		}
					
        message_begin(MSG_ONE_UNRELIABLE, gMsgSayText, _, id)
        write_byte(id)
        write_string(lInput)
        message_end()
					
        if(lChatTeam[0] != "U")
		{
			message_begin(MSG_ONE_UNRELIABLE, gMsgTeamInfo, _, id)
			write_byte(id)
			write_string(lPlayerTeam)
			message_end()
        }

        return PLUGIN_HANDLED
	}
	
    for(new i = 1; i <= gMaxPlayers; i++)
	{
		if(lChatTeam[0] != "U")
		{
			get_user_team(i, lPlayerTeam, charsmax(lPlayerTeam))
					
			message_begin(MSG_ONE_UNRELIABLE, gMsgTeamInfo, _, i)
			write_byte(i)
			write_string(lChatTeam)
			message_end()
        }

		message_begin(MSG_ONE_UNRELIABLE, gMsgSayText, _, i)
		write_byte(i)
		write_string(lInput)
		message_end()
					
		if(lChatTeam[0] != "U")
		{
			message_begin(MSG_ONE_UNRELIABLE, gMsgTeamInfo, _, i)
			write_byte(i)
			write_string(lPlayerTeam)
			message_end()
		}
	}

    return PLUGIN_HANDLED
}