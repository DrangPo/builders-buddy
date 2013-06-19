// LSL script generated: child.modules.child - group rezzer.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013

string ALL_MODULES = "all";
integer BB_API = -11235813;
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
string VAR_REMOVE_TAG = "group_remove_tag";
string VAR_PREFIX = "group_prefix";
string VAR_POSTFIX = "group_postfix";
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

////////////////////
integer is_group_match(string prefix,string group,string postfix,string name){
    list group_names = get_group_names(name,prefix,postfix);
    debug(DEBUG,("Groups: " + llDumpList2String(group_names,", ")));
    integer i;
    integer group_count = llGetListLength(group_names);
    for ((i = 0); (i < group_count); (i++)) {
        if ((group == llList2String(group_names,i))) return TRUE;
    }
    return FALSE;
}

////////////////////
string get_base_name(string prefix,string postfix,string name){
    integer end = 0;
    integer start = 1;
    if ((llGetSubString(name,0,0) == prefix)) {
        (end = llSubStringIndex(name,postfix));
        if ((end == (-1))) return name;
    }
    else  {
        return name;
    }
    return llGetSubString(name,(end + 1),(-1));
}

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
initialize(){
    set(VAR_REMOVE_TAG,"N");
    set(VAR_PREFIX,"[");
    set(VAR_POSTFIX,"]");
}

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

//==============================================================================
//Group Rezzer Functions
//==============================================================================

////////////////////
clean_name(){
    string new_name = get_base_name(get(VAR_PREFIX,""),get(VAR_POSTFIX,""),llGetObjectName());
    llSetObjectName(new_name);
}

////////////////////
got_message(){
    debugl(TRACE,["creator.got_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "clear_scripts")) {
        if (is_yes(VAR_REMOVE_TAG,"N")) clean_name();
        llRemoveInventory(llGetScriptName());
        return;
    }
    if ((msg_command == "mod_say")) {
        (msg_command = llList2String(msg_details,0));
        (msg_details = llList2List(msg_details,1,(-1)));
        got_parent_module_message();
        return;
    }
}

//==============================================================================
// BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received a message meant only for modules
// to handle directly
//==============================================================================
got_parent_module_message(){
    debugl(TRACE,["got_parent_module_message",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "clean_group")) {
        string group_name = llList2String(msg_details,0);
        debug(DEBUG,("Cleaning group name: " + group_name));
        if (is_group_match(get(VAR_PREFIX,""),group_name,get(VAR_POSTFIX,""),llGetObjectName())) {
            llDie();
        }
    }
}

////////////////////
////////////////////
////////////////////
default {

	state_entry() {
        initialize();
    }

	
	link_message(integer sender_num,integer number,string message,key id) {
        initialize();
        if (parse([ALL_MODULES],number,message,id)) {
            got_message();
        }
    }
}
