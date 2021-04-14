#include <sscanf2>
#include <YSI_Coding\y_va>
#include <Pawn.Regex>

#define DC_CMD:%0(%1,%2,%3)          \
			forward dc_cmd_%0(%1,%2,%3); \
			public dc_cmd_%0(%1,%2,%3)

IsCommandWithoutArgs(text[]) {
	new Regex:r = Regex_New("[?][A-Za-z]+");
	new check = Regex_Check(text, r);
	Regex_Delete(r);
	return check;
}

IsCommandWithArgs(text[]) {
	new Regex:r = Regex_New("[?][A-Za-z][ A-za-z0-9]+");
	new check = Regex_Check(text, r);
	Regex_Delete(r);
	return check;
}

stock SendDCByName(channel[], msg[], va_args<>) {
    va_format(msg, 1000, msg, va_start<2>);
    return DCC_SendChannelMessage(DCC_FindChannelByName(channel), msg);
}
//Processing

public DCC_OnMessageCreate(DCC_Message:message) {
	new DCC_Channel:channel;
	new DCC_User:author,
		channel_name[100 + 1],
		user_name[32 + 1],
		messageEx[1000]
	;
	DCC_GetMessageChannel(message, channel);
	DCC_GetMessageAuthor(message, author);
	DCC_GetChannelName(channel, channel_name);
	DCC_GetUserName(author, user_name);
	DCC_GetMessageContent(message, messageEx);
	if(!strlen(user_name) || !strlen(channel_name) || !strlen(messageEx) || !strcmp(user_name, BOT_NAME, true)) return 0;
	new callfucn[21], command[15];
	if (IsCommandWithoutArgs(messageEx)) {
		sscanf(messageEx, "s[15]", command);
		strdel(command, 0, 1);
		format(callfucn, sizeof(callfucn), "dc_cmd_%s", command);
		CallLocalFunction(callfucn, "sss", user_name, "\1", channel_name);
		return 1;
	}
	if (IsCommandWithArgs(messageEx)) {
		new args[985];
		sscanf(messageEx, "s[15]s[985]", command, args);
		strdel(command, 0, 1);
		format(callfucn, sizeof(callfucn), "dc_cmd_%s", command);
		CallLocalFunction(callfucn, "sss", user_name, args, channel_name);
	}
	return 1;
}
