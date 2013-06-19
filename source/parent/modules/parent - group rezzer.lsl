// LSL script generated: parent.modules.parent - group rezzer.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013

string ALL_MODULES = "all";
integer BB_API = -11235813;
string MANAGER = "manager";
string TYPE_CHILD = "C";
string TYPE_PARENT = "P";
integer TRACE = 0;
integer DEBUG = 1;
integer INFO = 2;
integer WARNING = 3;
integer ERROR = 4;
integer DEBUG_LEVEL = TRACE;
list values = [];
list vars = [];
string MENU_TYPE_ADMIN = "A";
string MENU_TYPE_EVERYONE = "E";
string MENU_TYPE_NONE = "X";
string VAR_MOD_EVENTS = "mod_events";
string VAR_MOD_MENU_DESC = "mod_menu_desc";
string VAR_MOD_MENU_TYPE = "mod_menu_type";
string VAR_MOD_NAME = "mod_name";
string VAR_MOD_TYPE = "mod_type";
string msg_command;
list msg_details;
string msg_module;
string module = "";
string VAR_PREFIX = "group_prefix";
string VAR_POSTFIX = "group_postfix";

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

//==============================================================================
// Group Rezzer Constants
//==============================================================================
string VAR_CLEAN_BEFORE_REZ = "clean_before_rez";
integer ITEMS_PER_PAGE = 8;

//==============================================================================
// Group Rezzer Variables
//==============================================================================
integer need_rebuild = TRUE;
list groups;
string action = "";
integer page = 0;
////////////////////
debug(integer level,string text){
    if ((level >= DEBUG_LEVEL)) llOwnerSay(((((("[" + llGetScriptName()) + "]") + get_level_text(level)) + " ") + text));
}

////////////////////
debugl(integer level,list lines){
    debug(level,llDumpList2String(lines,"\n\t"));
}

string get_level_text(integer level){
    if ((level == TRACE)) return "[trace]";
    if ((level == DEBUG)) return "[debug]";
    if ((level == INFO)) return "[info]";
    if ((level == WARNING)) return "[warning]";
    if ((level == ERROR)) return "[error]";
    return "";
}

//==============================================================================
//Storage Functions
//==============================================================================

////////////////////
string get(string name,string default_value){
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) return llList2String(values,iFound);
    return default_value;
}

////////////////////
list get_list(string varName,list default_list){
    integer iFound = llListFindList(vars,[varName]);
    if ((iFound != (-1))) {
        return llParseStringKeepNulls(llList2String(values,iFound),["|"],[""]);
    }
    return default_list;
}

////////////////////
integer is_yes(string var,string default_value){
    return (llToUpper(get(var,default_value)) == "Y");
}

////////////////////
set(string name,string value){
    (name = llToLower(name));
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) {
        (values = llListReplaceList(values,[value],iFound,iFound));
    }
    else  {
        (vars += name);
        (values += value);
    }
}

////////////////////
set_list(string name,list values){
    set(name,llDumpList2String(values,"|"));
}

//==============================================================================
//Communication functions
//==============================================================================

// message: <source>|<target>|<command>
// id: <details...>
////////////////////
integer parse(list targets,integer number,string message,string id){
    if ((number != BB_API)) return FALSE;
    list parts = llParseStringKeepNulls(((string)id),["|"],[]);
    if ((llGetListLength(parts) != 3)) return FALSE;
    integer num_targets = llGetListLength(targets);
    integer i;
    string target = llList2String(parts,1);
    for ((i = 0); (i < num_targets); (i++)) {
        if ((llList2String(targets,i) == target)) {
            (msg_module = llList2String(parts,0));
            (msg_command = llList2String(parts,2));
            (msg_details = llParseStringKeepNulls(message,["|"],[]));
            debugl(TRACE,["common.comm.parse():",msg_module,msg_command,message]);
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
send(string source,string dest,string command,list details){
    debugl(TRACE,["common.common.send():",("dest: " + dest),("command: " + command),("details: " + llDumpList2String(details,"|"))]);
    llMessageLinked(LINK_THIS,BB_API,llDumpList2String(details,"|"),llDumpList2String([source,dest,command],"|"));
}

//==============================================================================
// Utility Functions
//==============================================================================

////////////////////
string get_short_name(string longName){
    (longName = llSHA1String(longName));
    string shortName;
    integer ptr = 0;
    integer strLength = llStringLength(longName);
    string char;
    for ((ptr = 0); (ptr < strLength); (ptr += 2)) {
        integer ord = ((integer)("0x" + llGetSubString(longName,ptr,(ptr + 1))));
        if ((ord <= 0)) {
            (char = "");
        }
        else  if ((ord < 128)) {
            (char = llUnescapeURL(get_url_code(ord)));
        }
        else  if ((ord < 2048)) {
            (char = llUnescapeURL((get_url_code((((ord >> 6) & 31) | 192)) + get_url_code(((ord & 63) | 128)))));
        }
        else  if ((ord < 65536)) {
            (char = llUnescapeURL(((get_url_code((((ord >> 12) & 15) | 224)) + get_url_code((((ord >> 6) & 63) | 128))) + get_url_code(((ord & 63) | 128)))));
        }
        else  {
            (char = llUnescapeURL((((get_url_code((((ord >> 18) & 15) | 240)) + get_url_code((((ord >> 12) & 63) | 128))) + get_url_code((((ord >> 6) & 63) | 128))) + get_url_code(((ord & 63) | 128)))));
        }
        (shortName += char);
    }
    return shortName;
}

////////////////////
string get_url_code(integer b){
    string hexd = "0123456789ABCDEF";
    return (("%" + llGetSubString(hexd,(b >> 4),(b >> 4))) + llGetSubString(hexd,(b & 15),(b & 15)));
}

//==============================================================================
//Manager Core Functions
//==============================================================================

////////////////////
check_name(){
    (module = get_short_name(llGetScriptName()));
    (module = llDumpList2String(llParseStringKeepNulls(module,["|"],[]),""));
    debugl(TRACE,["mod_check_name():",((((("Module: " + llGetScriptName()) + ", short name: ") + module) + ", length: ") + ((string)llStringLength(module)))]);
}

////////////////////
integer handle_message(){
    debugl(TRACE,(["module.core.handle_message()",msg_module,msg_command] + msg_details));
    if ((msg_module == MANAGER)) {
        if ((msg_command == "reset")) {
            llResetScript();
            return TRUE;
        }
        if ((msg_command == "register")) {
            debug(DEBUG,"Registration received");
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
register(string module_type,string menu_type,list events,string label,string desc){
    (menu_type = llToUpper(menu_type));
    if ((((menu_type != MENU_TYPE_ADMIN) && (menu_type != MENU_TYPE_EVERYONE)) && (menu_type != MENU_TYPE_NONE))) {
        llOwnerSay("mod_register: Invalid menu type specified, please check script.");
        return;
    }
    if (((module_type != TYPE_PARENT) && (module_type != TYPE_CHILD))) {
        llOwnerSay("mod_register: Invalid module type specified, please check script.");
        return;
    }
    list details = [llGetScriptName(),module_type,menu_type,llDumpList2String(events,","),label,desc];
    send_manager("register",details);
}

////////////////////
register_quick(){
    string modType = get(VAR_MOD_TYPE,TYPE_CHILD);
    string modName = get(VAR_MOD_NAME,"SET_MOD_NAME");
    string menuDesc = get(VAR_MOD_MENU_DESC,"(No description)");
    string menuType = get(VAR_MOD_MENU_TYPE,MENU_TYPE_NONE);
    list modEvents = get_list(VAR_MOD_EVENTS,[]);
    register(modType,menuType,modEvents,modName,menuDesc);
}

////////////////////
send_manager(string command,list details){
    send(module,MANAGER,command,details);
}


////////////////////
mod_changed(integer change){
    if ((change & CHANGED_INVENTORY)) check_name();
}

////////////////////
mod_state_entry(){
    debug(DEBUG,"====================");
    debug(DEBUG,"   SCRIPT STARTED   ");
    debug(DEBUG,"====================");
    check_name();
    register_quick();
}

//==============================================================================
//Group Rezzer Core Functions
//==============================================================================

////////////////////
list get_group_names(string text,string prefix,string postfix){
    integer end = 0;
    integer start = 1;
    if ((llGetSubString(text,0,0) == prefix)) {
        (end = llSubStringIndex(text,postfix));
        if ((end == (-1))) return [];
    }
    else  {
        return [];
    }
    list groups = llParseStringKeepNulls(llGetSubString(text,start,(end - 1)),[","],[]);
    return groups;
}

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// mod_type:
//   Indicates if this module should link to the parent or component scripts.  
//   Set to one of:
//     CORE_TYPE_PARENT - Module intended for use in the parent prim
//     CORE_TYPE_CHILD - Module intended for use in the child prims;
//==============================================================================
// menu_type:
//   The type of button to be added to the menu.  Set to one of:
//   MOD_MENU_TYPE_ADMIN - Button is seen only by administrators/creators
//   MOD_MENU_TYPE_EVERYONE - Button is seen by everyone
//   MOD_MENU_TYPE_NONE - No button will be shown.     
//==============================================================================
// mod_name:
//   The name of the module.  If menu_type is set to MOD_MENU_TYPE_ADMIN
//   or MOD_MENU_TYPE_EVERYONE, this will be used as the label on the button.    
//==============================================================================
// mod_menu_desc:
//   Description of the module. Will be included in the text of the menu when
//   the module's button is display.    
//==============================================================================
// mod_events:
//   Events that this module wishes to review and possibly cancel.  These can
//   only be events that are explicitly available as cancellable in the base or
//   component script.  This should be set as a list using setList();
//==============================================================================
// group_prefix:
//   Text that is always included at the beginning of the group name.
//==============================================================================
// group_postfix:
//   Text that is always included at the beginning of the group name.
//==============================================================================
initialize(){
    set(VAR_MOD_TYPE,TYPE_PARENT);
    set(VAR_MOD_NAME,"Group Rezzer");
    set(VAR_MOD_MENU_TYPE,MENU_TYPE_NONE);
    set(VAR_MOD_MENU_DESC,"Rez a group of objects");
    set_list(VAR_MOD_EVENTS,["build","clean"]);
    set(VAR_PREFIX,"[");
    set(VAR_POSTFIX,"]");
    set(VAR_CLEAN_BEFORE_REZ,"Y");
}


//==============================================================================
// Group Rezzer Functions
//==============================================================================

////////////////////
build_groups(){
    debug(TRACE,"grouprezzer.buildGroups()");
    if ((!need_rebuild)) return;
    string prefix = get(VAR_PREFIX,"");
    string postfix = get(VAR_POSTFIX,"");
    (groups = []);
    integer count = llGetInventoryNumber(INVENTORY_OBJECT);
    integer i;
    for ((i = 0); (i < count); (i++)) {
        string name = llGetInventoryName(INVENTORY_OBJECT,i);
        list test_groups = get_group_names(name,prefix,postfix);
        integer group_count = llGetListLength(test_groups);
        if ((group_count > 0)) {
            integer j;
            for ((j = 0); (j < group_count); (j++)) {
                string test_group = llList2String(test_groups,j);
                if ((llListFindList(groups,[test_group]) == (-1))) {
                    debug(DEBUG,("Adding rez group: " + test_group));
                    (groups += [test_group]);
                }
            }
        }
    }
    (groups = llListSort(groups,1,TRUE));
    (need_rebuild = FALSE);
}

////////////////////
got_menu_reply(){
    debugl(TRACE,["parent - group rezzer.got_menu_reply()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((action == "build")) {
        string user_name = llList2String(msg_details,0);
        string user_key = ((key)llList2Key(msg_details,1));
        if ((msg_command == "<ALL>")) {
            debug(DEBUG,"Rezzing all objects");
            send_manager("rez",[user_key]);
        }
        else  if ((msg_command == "<NEXT>")) {
            (page++);
            show_build_menu(user_key);
            return;
        }
        else  if ((msg_command == "<PREV>")) {
            (page--);
            if ((page < 0)) (page = 0);
            show_build_menu(user_key);
            return;
        }
        else  if ((msg_command == "<BACK>")) {
            send_manager("top_menu",[user_key]);
        }
        else  {
            build_groups();
            integer found = llListFindList(groups,[msg_command]);
            if ((found != (-1))) {
                if (is_yes("clean_before_rez","N")) {
                    send_manager("mod_say",["clean_group",msg_command,user_key,user_name]);
                }
                send_manager("rez",[user_key,get("group_prefix",""),msg_command,get("group_postfix","")]);
            }
        }
    }
    else  if ((action == "clean")) {
        string user_name = llList2String(msg_details,0);
        string user_key = ((key)llList2Key(msg_details,1));
        if ((msg_command == "<ALL>")) {
            debug(DEBUG,"Cleaning all objects");
            send_manager("clean",[user_key,user_name]);
            return;
        }
        else  if ((msg_command == "<BACK>")) {
            send_manager("top_menu",[user_key]);
        }
        else  if ((msg_command == "<NEXT>")) {
            (page++);
            show_clean_menu(user_key);
            return;
        }
        else  if ((msg_command == "<PREV>")) {
            (page--);
            if ((page < 0)) (page = 0);
            show_clean_menu(user_key);
            return;
        }
        else  {
            build_groups();
            integer found = llListFindList(groups,[msg_command]);
            if ((found != (-1))) {
                send_manager("mod_say",["clean_group",msg_command,user_key,user_name]);
            }
        }
    }
    (action = "");
}

////////////////////
got_message(){
    debugl(TRACE,["creator.got_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "reset")) llResetScript();
    if ((msg_command == "base_reset")) {
        llResetScript();
        return;
    }
    if ((msg_command == "menu_requested")) {
        debug(DEBUG,"Requested to show menu!");
        (page = 0);
        show_build_menu(llList2Key(msg_details,1));
        return;
    }
    if ((msg_command == "menu_reply")) {
        (msg_command = llList2String(msg_details,0));
        (msg_details = llList2List(msg_details,1,(-1)));
        got_menu_reply();
        return;
    }
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received a cancellable request.  This
// must return TRUE to cancel the event, or FALSE to allow it to continue.
// Unless your module has a specific need to stop the event from happening, this
// should normally return FALSE.
//
//Only cancellable events listed in mod_events will be seen here.
//==============================================================================
integer got_request(){
    debugl(TRACE,["creator.got_request()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "build")) {
        (action = "build");
        (page = 0);
        show_build_menu(llList2Key(msg_details,0));
        return TRUE;
    }
    if ((msg_command == "clean")) {
        (action = "clean");
        (page = 0);
        show_clean_menu(llList2Key(msg_details,0));
        return TRUE;
    }
    return FALSE;
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
//==============================================================================
parse_message(){
    debugl(TRACE,["creator.mod_parse_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "request_event")) {
        (msg_command = llList2String(msg_details,0));
        (msg_details = llList2List(msg_details,1,(-1)));
        integer cancelled = got_request();
        send_manager("request_ack",[msg_command,cancelled]);
    }
    else  {
        got_message();
    }
}

////////////////////
show_build_menu(key user){
    build_groups();
    string text = "Select which group of objects to build:";
    send_manager("menu",(([user,text] + get_group_buttons()) + ["<BACK>"]));
}

////////////////////
show_clean_menu(key user){
    build_groups();
    string text = "Select which group of objects to remove:";
    send_manager("menu",(([user,text] + get_group_buttons()) + ["<BACK>"]));
}

////////////////////
list get_group_buttons(){
    list buttons = [];
    if ((page == 0)) (buttons = ["<ALL>"]);
    integer i;
    integer count = llGetListLength(groups);
    integer last_page = FALSE;
    integer max = (((page + 1) * ITEMS_PER_PAGE) + 1);
    if ((max >= count)) {
        (last_page = TRUE);
        (max = count);
    }
    debug(DEBUG,("Max: " + ((string)max)));
    debug(DEBUG,("Count: " + ((string)count)));
    for ((i = (page * ITEMS_PER_PAGE)); (i < max); (i++)) {
        (buttons += [llList2String(groups,i)]);
    }
    if ((page > 0)) (buttons += ["<PREV>"]);
    if ((!last_page)) (buttons += ["<NEXT>"]);
    return buttons;
}


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
default {

	state_entry() {
        initialize();
        mod_state_entry();
        build_groups();
    }

	
	changed(integer change) {
        mod_changed(change);
        if ((change & CHANGED_INVENTORY)) (need_rebuild = TRUE);
    }


	link_message(integer sender_num,integer number,string message,key id) {
        if (parse([module,ALL_MODULES],number,message,id)) {
            if (handle_message()) return;
            parse_message();
        }
    }
}
