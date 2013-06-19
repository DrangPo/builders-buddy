// LSL script generated: parent.parent - manager.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013

string ALL_MODULES = "all";
string BASE = "base";
integer BB_API = -11235813;
string MANAGER = "manager";
string TYPE_PARENT = "P";
integer TRACE = 0;
integer DEBUG = 1;
integer INFO = 2;
integer WARNING = 3;
integer ERROR = 4;
integer DEBUG_LEVEL = TRACE;
string msg_command;
list msg_details;
string msg_module;
list values = [];
list vars = [];
string MENU_TYPE_ADMIN = "A";
string MENU_TYPE_EVERYONE = "E";
string VAR_ALLOW_CLEAN = "allow_clean";
string VAR_ALLOW_GROUP = "allow_group";
string VAR_ALLOW_FORGET = "allow_forget";
string VAR_ALLOW_RECORD = "allow_record";
string VAR_CONFIRM_CLEAN = "confirm_clean";
string VAR_CONFIRM_FINISH = "confirm_finish";
string VAR_CREATORS = "creators";
string VAR_DELETE_ON_REZ = "delete_on_rez";
string VAR_EVENT_TIMEOUT = "event_timeout";
string VAR_FULL_RIGHTS = "full_rights";
string VAR_MENU_LISTEN_TIME = "menu_listen";
string VAR_MENU_ON_TOUCH = "menu_on_touch";
string VAR_SAFE_CLEAN = "safe_clean";
string VAR_CLEAN_WARNING = "WARNING: Cleaning will make these objects delete from the region.  They do NOT go back into inventory.\n\nClean?";
string VAR_FINISH_WARNING = "WARNING: Pressing Finish will freeze these items into position and remove the Builder\\'s Buddy scripts.  You will have to move/delete them manually after this point.\n\nFinish?";
string base_type = "";
list cancellableEvents = ["build","clean"];
list last_event_details = [];
string last_event_name = "";
integer last_event_pending = 0;
integer last_event_permitted = FALSE;
integer last_event_timeout = 0;
key last_event_user = NULL_KEY;
string menu_action = "";
integer menu_channel;
integer menu_handle;
key menu_user = NULL_KEY;
list mod_descs = [];
list mod_events = [];
list mod_menus = [];
list mod_scripts = [];
list mod_types = [];
string module;
integer timeout;
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
//Storage Functions
//==============================================================================

////////////////////
string get(string name,string default_value){
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) return llList2String(values,iFound);
    return default_value;
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

//menuFormat Created by Huns Valens
////////////////////
list menuFormat(list theButtons){
    list btnOut;
    integer nButtons = llGetListLength(theButtons);
    integer nLastRow = (nButtons % 3);
    integer lastRow = (nButtons - nLastRow);
    integer row;
    for ((row = nButtons); (row >= nLastRow); (row -= 3)) {
        (btnOut += llList2List(theButtons,row,(row + 2)));
    }
    for ((row = 0); (row < nLastRow); (row++)) {
        (btnOut += llList2String(theButtons,row));
    }
    return btnOut;
}

//==============================================================================
//Manager Core Functions
//==============================================================================

////////////////////
ack_event(string eventName,integer cancel){
    if ((eventName == last_event_name)) {
        if (cancel) {
            (last_event_permitted = FALSE);
            do_event();
            clear_event();
        }
        else  {
            (--last_event_pending);
            if ((last_event_pending == 0)) {
                do_event();
                clear_event();
            }
        }
    }
}

////////////////////
integer can_clean(key id){
    if (is_full_rights(id)) {
        if (is_yes(VAR_SAFE_CLEAN,"N")) return FALSE;
    }
    return is_yes(VAR_ALLOW_CLEAN,"N");
}

////////////////////
integer can_show_menu(key user,integer same_group){
    debugl(TRACE,["manager.menu.can_show_menu()",("user: " + ((string)user)),("same_group: " + ((string)same_group))]);
    if ((user == llGetOwner())) {
        debug(INFO,"Can show menu, object owner");
        return TRUE;
    }
    if (is_yes(VAR_ALLOW_GROUP,"N")) {
        key group = llList2Key(llGetObjectDetails(llGetKey(),[OBJECT_GROUP]),0);
        if ((group != NULL_KEY)) {
            if (same_group) {
                debug(INFO,"Can show menu, same group");
                return TRUE;
            }
        }
    }
    return FALSE;
}

////////////////////
clear_event(){
    (last_event_name = "");
    (last_event_details = []);
    (last_event_pending = 0);
    (last_event_timeout = 0);
    (last_event_user = NULL_KEY);
    (last_event_permitted = TRUE);
}

////////////////////
confirm_clean(key user){
    manager_stop_listening();
    list buttons = ["Clean","Cancel"];
    (menu_action = "clean");
    manager_start_listening(user,MANAGER);
    llDialog(user,VAR_CLEAN_WARNING,menuFormat(buttons),menu_channel);
}

////////////////////
confirm_finish(key user){
    manager_stop_listening();
    list buttons = ["Finish","Cancel"];
    (menu_action = "finish");
    manager_start_listening(user,MANAGER);
    llDialog(user,VAR_FINISH_WARNING,menuFormat(buttons),menu_channel);
}

////////////////////
do_event(){
    send(MANAGER,BASE,"do_event",([last_event_name,last_event_user,last_event_permitted] + last_event_details));
}

////////////////////
integer is_listener(string event_name,string module){
    integer found = llListFindList(mod_scripts,[module]);
    if ((found != (-1))) {
        list events = llParseStringKeepNulls(llList2String(mod_events,found),[","],[]);
        if ((llListFindList(events,[event_name]) != (-1))) return TRUE;
    }
    return FALSE;
}

////////////////////
integer is_full_rights(key user){
    if (is_yes(VAR_FULL_RIGHTS,"N")) return TRUE;
    string creators = get(VAR_CREATORS,"");
    list lCreators = [];
    if ((creators != "")) {
        (lCreators = llParseStringKeepNulls(creators,[","],[]));
    }
    else  {
        (lCreators = [llGetOwner()]);
    }
    if ((llListFindList(lCreators,[user]) != (-1))) return TRUE;
    return FALSE;
}

////////////////////
integer is_module(string module){
    return (llListFindList(mod_scripts,[module]) != (-1));
}

////////////////////
integer listener_count(string event_name){
    integer count = llGetListLength(mod_events);
    integer i;
    integer found = 0;
    list events;
    for ((i = 0); (i < count); (i++)) {
        (events = llParseStringKeepNulls(llList2String(mod_events,i),[","],[]));
        if ((llListFindList(events,[event_name]) != (-1))) (++found);
    }
    return found;
}

////////////////////
integer manager_menu_handle_message(){
    if (is_module(msg_module)) {
        if ((msg_command == "menu")) {
            show_mod_menu(msg_module,((key)llList2String(msg_details,0)),llList2String(msg_details,1),menuFormat(llList2List(msg_details,2,(-1))));
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
integer menu_listen(integer channel,string name,key id,string message){
    if ((channel == 0)) return FALSE;
    if ((channel != menu_channel)) return FALSE;
    manager_stop_listening();
    debugl(TRACE,["manager.menu.listen()",("message: " + message),("id: " + ((string)id))]);
    if ((module == MANAGER)) {
        if ((message == "Build")) {
            request_event(id,"build",[]);
            return TRUE;
        }
        else  if ((message == "Nudge")) {
            send_base("move_base",[]);
            return TRUE;
        }
        else  if ((message == "Clean")) {
            integer need_confirm = is_yes(VAR_CONFIRM_CLEAN,"Y");
            if (can_clean(id)) {
                if ((menu_action == "")) {
                    if (need_confirm) {
                        confirm_clean(id);
                        return TRUE;
                    }
                }
                if (((!need_confirm) || (menu_action == "clean"))) request_event(id,"clean",["",""]);
            }
            return TRUE;
        }
        else  if ((message == "Finish")) {
            integer need_confirm = is_yes(VAR_CONFIRM_FINISH,"Y");
            if ((menu_action == "")) {
                if (need_confirm) {
                    confirm_finish(id);
                    return TRUE;
                }
            }
            if (((!need_confirm) || (menu_action == "finish"))) {
                send_child("clear_scripts",[]);
                send(MANAGER,BASE,"send_child",["clear_scripts"]);
            }
            return TRUE;
        }
        else  {
            integer iFound = llListFindList(mod_menus,[message]);
            if ((iFound != (-1))) {
                integer subMenu = FALSE;
                string type = llList2String(mod_types,iFound);
                if ((type == MENU_TYPE_ADMIN)) {
                    if (is_full_rights(id)) (subMenu = TRUE);
                }
                else  {
                    (subMenu = TRUE);
                }
                if (subMenu) {
                    debug(DEBUG,"Sending to module");
                    string sub_module = llList2String(mod_scripts,iFound);
                    manager_start_listening(id,sub_module);
                    send_module(sub_module,"request_menu",[name,id,is_full_rights(id)],FALSE);
                }
                return TRUE;
            }
        }
    }
    else  {
        send_module(module,"menu_reply",[message,name,id],FALSE);
        (module = "");
        return TRUE;
    }
    return FALSE;
}

////////////////////
integer menu_touch_start(integer num_detected){
    if (is_yes(VAR_MENU_ON_TOUCH,"Y")) {
        if (can_show_menu(llDetectedKey(0),llDetectedGroup(0))) {
            show_menu(llDetectedKey(0));
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
request_event(key user,string event_name,list details){
    clear_event();
    (last_event_name = event_name);
    (last_event_details = details);
    (last_event_user = user);
    if ((llListFindList(cancellableEvents,[event_name]) != (-1))) {
        integer mod_count = listener_count(event_name);
        if ((mod_count > 0)) {
            debug(DEBUG,(((("Sending " + event_name) + " request to ") + ((string)mod_count)) + " modules"));
            (last_event_pending = mod_count);
            (last_event_timeout = (llGetUnixTime() + ((integer)get(VAR_EVENT_TIMEOUT,"5"))));
            send_module(ALL_MODULES,"request_event",([event_name,user] + details),FALSE);
            return;
        }
    }
    debug(DEBUG,(("Auto-approving " + event_name) + " request"));
    do_event();
}

////////////////////
show_menu(key user){
    manager_stop_listening();
    (menu_action = "");
    integer isFull = is_full_rights(user);
    integer is_clean = can_clean(user);
    string text = "";
    list buttons = [];
    (buttons += ["Build","Nudge"]);
    (text += ("Build: Rez pieces and position them" + "\nNudge: move pieces into place"));
    if (is_clean) {
        (text += "\nClean: De-rez all pieces");
        (buttons += ["Clean"]);
    }
    (text += "\nFinish: Freeze pieces in place and delete BB scripts");
    (buttons += ["Finish"]);
    integer i;
    integer count = llGetListLength(mod_scripts);
    integer include;
    for ((i = 0); (i < count); (i++)) {
        (include = FALSE);
        string menuType = llList2String(mod_types,i);
        if ((menuType == MENU_TYPE_ADMIN)) {
            if (isFull) (include = TRUE);
        }
        else  {
            if ((menuType == MENU_TYPE_EVERYONE)) (include = TRUE);
        }
        if (include) {
            if ((text != "")) (text += "\n");
            (text += ((llList2String(mod_menus,i) + " - ") + llList2String(mod_descs,i)));
            (buttons += [llList2String(mod_menus,i)]);
        }
    }
    manager_start_listening(user,MANAGER);
    llDialog(user,text,menuFormat(buttons),menu_channel);
}

////////////////////
show_mod_menu(string module,key user,string text,list buttons){
    manager_start_listening(user,module);
    llDialog(user,text,buttons,menu_channel);
}

////////////////////
manager_start_listening(key user,string listening_module){
    if (((menu_user != NULL_KEY) && (menu_user != user))) manager_stop_listening();
    if ((menu_handle == 0)) {
        (menu_channel = llFloor(llFrand(((-9999999.0) - (-100)))));
        (menu_handle = llListen(menu_channel,"",user,""));
    }
    (module = listening_module);
    send_module(ALL_MODULES,"listening",[menu_channel,user],FALSE);
    (timeout = (llGetUnixTime() + llFloor(((float)get(VAR_MENU_LISTEN_TIME,"30.0")))));
}

////////////////////
manager_stop_listening(){
    if ((menu_handle != 0)) llListenRemove(menu_handle);
    (menu_channel = 0);
    (menu_handle = 0);
    (menu_user = NULL_KEY);
    (timeout = 0);
    send_module(ALL_MODULES,"not_listening",[],TRUE);
    return;
}

////////////////////
register_mod(string module,string module_type,string menu_type,string events,string label,string desc){
    debugl(TRACE,["manager.core.register_mod()",("module: " + module),("module type: " + module_type),("menu type: " + menu_type),("events: " + events),("menuLabel: " + label),("menuDesc: " + desc)]);
    if ((module_type != base_type)) {
        debugl(WARNING,["REJECTED manager_register_mod:",("script type: " + base_type),("module type: " + module_type)]);
        return;
    }
    remove_mod(module);
    (mod_scripts += [module]);
    (mod_types += [menu_type]);
    (mod_events += [events]);
    (mod_menus += [label]);
    (mod_descs += [desc]);
    send_module(module,"register",[TRUE],TRUE);
    llOwnerSay(("Activated module: " + label));
    return;
}

////////////////////
remove_mod(string module){
    integer iFound = llListFindList(mod_scripts,[module]);
    if ((iFound != (-1))) {
        (mod_scripts = llDeleteSubList(mod_scripts,iFound,iFound));
        (mod_types = llDeleteSubList(mod_types,iFound,iFound));
        (mod_events = llDeleteSubList(mod_events,iFound,iFound));
        (mod_menus = llDeleteSubList(mod_menus,iFound,iFound));
        (mod_descs = llDeleteSubList(mod_menus,iFound,iFound));
    }
}

////////////////////
requested_event(string event_name,list event_details){
    if ((event_name == "die_on_clean")) {
        key user = ((key)llList2String(event_details,1));
        integer can_die = is_full_rights(user);
        send_base("event_ack",([msg_command,can_die] + llList2List(event_details,1,(-1))));
    }
    return;
}

////////////////////
send_base(string command,list details){
    debugl(TRACE,["manager.core.send_base()",("command: " + command),("details: " + llDumpList2String(details,"|"))]);
    send(MANAGER,BASE,command,details);
}

////////////////////
send_module(string destModule,string command,list details,integer force){
    if ((!force)) {
        if ((llGetListLength(mod_scripts) == 0)) return;
    }
    send(MANAGER,destModule,command,details);
}

////////////////////
send_child(string command,list details){
    send(MANAGER,BASE,"send_child",([command] + details));
}

////////////////////
integer manager_core_handle_message(){
    if ((msg_module == BASE)) {
        if ((msg_command == "base_reset")) {
            (base_type = llList2String(msg_details,0));
            send_base("manager_ready",[llGetFreeMemory()]);
            return TRUE;
        }
        if ((msg_command == "request_event")) {
            requested_event(llList2String(msg_details,0),llList2List(msg_details,1,(-1)));
            return TRUE;
        }
        if ((msg_command == "rezzed")) {
            key object = ((key)llList2String(msg_details,0));
            key rez_user = ((key)llList2String(msg_details,1));
            string object_name = llList2String(msg_details,2);
            if (is_yes(VAR_DELETE_ON_REZ,"N")) {
                if (is_full_rights(rez_user)) {
                    llRemoveInventory(object_name);
                }
            }
            return TRUE;
        }
        return FALSE;
    }
    if (is_module(msg_module)) {
        if ((msg_command == "unregister")) {
            remove_mod(msg_module);
            return TRUE;
        }
        if ((msg_command == "record")) {
            if (is_yes(VAR_ALLOW_RECORD,"N")) send_base(msg_command,msg_details);
            return TRUE;
        }
        if ((msg_command == "clean")) {
            key user_key = ((key)llList2String(msg_details,0));
            string user_name = llList2String(msg_details,1);
            send_base("do_event",["clean",user_key,TRUE,user_name]);
            return TRUE;
        }
        if ((msg_command == "clear")) {
            if (is_yes(VAR_ALLOW_FORGET,"N")) send_base(msg_command,msg_details);
            return TRUE;
        }
        if ((msg_command == "mod_say")) {
            send_base("mod_say",msg_details);
            return TRUE;
        }
        if ((msg_command == "send_child")) {
            send_child(llList2String(msg_details,0),llList2List(msg_details,1,(-1)));
            return TRUE;
        }
        if ((msg_command == "request_ack")) {
            string event_name = llList2String(msg_details,0);
            if (is_listener(event_name,msg_module)) {
                integer cancelled = llList2Integer(msg_details,1);
                ack_event(event_name,cancelled);
            }
            return TRUE;
        }
        if ((msg_command == "rez")) {
            send_base(msg_command,msg_details);
            return TRUE;
        }
        if ((msg_command == "top_menu")) {
            key user = llList2Key(msg_details,0);
            if (can_show_menu(user,llSameGroup(user))) {
                show_menu(user);
            }
            return TRUE;
        }
        return FALSE;
    }
    if ((msg_command == "register")) {
        debugl(DEBUG,["manager.event.manager_event_link_message() - Got registration request"]);
        register_mod(msg_module,llList2String(msg_details,1),llList2String(msg_details,2),llList2String(msg_details,3),llList2String(msg_details,4),llList2String(msg_details,5));
        return TRUE;
    }
    return FALSE;
}

////////////////////
manager_event_state_entry(){
    send_module(ALL_MODULES,"reset",[],TRUE);
    send_base("manager_ready",[llGetFreeMemory()]);
}

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// VAR_ALLOW_CLEAN:
//   Is the user permitted to use the "Clean" menu option.  Must be set to "Y"
//   or "N".  If set to "N", will not display "Clean" in the menu.
//==============================================================================
// VAR_ALLOW_FORGET:
//   Is the user permitted to request child objects to delete/forget their
//   recorded position information.  Must be set to "Y" or "N".  Leave this as
//   "Y" for most cases.
//==============================================================================
//  VAR_ALLOW_GROUP:
//   Allow users that are in the same group (if set) as the parent object to
//   access the menu.  Must be set to "Y" or "N".
//==============================================================================
// VAR_CONFIRM_CLEAN:
//   When the user selects "Clean" from the menu, displays a "Are you sure?"
//   confirmation dialog.  Must be set to "Y" or "N".  Text to be displayed
//   can be changed in VAR_CLEAN_WARNING.
//==============================================================================
// VAR_CONFIRM_FINISH:
//   When the user selects "Finish" from the menu, displays a "Are you sure?"
//   confirmation dialog.  Must be set to "Y" or "N".  Text to be displayed
//   can be changed in VAR_FINISH_WARNING.
//==============================================================================
// VAR_CREATORS:
//   A List of UUIDs of users that this script will treat as object owner.
//==============================================================================
// VAR_EVENT_TIMEOUT:
//   How long to wait, in seconds, for registered modules to accept/reject
//   cancellable events.
//==============================================================================
// VAR_MENU_LISTEN_TIME:
//   How long the script will listen to a response, in seconds, when a menu
//   dialog is shown to the user.
//==============================================================================
// VAR_MENU_ON_TOUCH:
//   If set to "Y", will display a menu to eligible users when they touch the
//   object.  If set to "N", menu can only be activated by request of other
//   modules.
//==============================================================================
initialize(){
    set(VAR_ALLOW_CLEAN,"Y");
    set(VAR_ALLOW_FORGET,"Y");
    set(VAR_ALLOW_GROUP,"Y");
    set(VAR_CONFIRM_CLEAN,"Y");
    set(VAR_CONFIRM_FINISH,"Y");
    set_list(VAR_CREATORS,[]);
    set(VAR_EVENT_TIMEOUT,"5");
    set(VAR_MENU_LISTEN_TIME,"30.0");
    set(VAR_MENU_ON_TOUCH,"Y");
}

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

////////////////////
////////////////////
////////////////////
default {

	state_entry() {
        initialize();
        (base_type = TYPE_PARENT);
        manager_event_state_entry();
    }

	
	link_message(integer sender_num,integer number,string message,key id) {
        if (parse([MANAGER,ALL_MODULES],number,message,id)) {
            if (manager_core_handle_message()) return;
            if (manager_menu_handle_message()) return;
            return;
        }
    }

	
	listen(integer channel,string name,key id,string message) {
        if (menu_listen(channel,name,id,message)) return;
    }

	
	touch_start(integer num_detected) {
        if (menu_touch_start(num_detected)) return;
    }
}
