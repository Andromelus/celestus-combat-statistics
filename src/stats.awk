BEGIN {
    FS = "="
    round = 0
    define_next_round_pattern(round)
    expected_version = "3;"
}

function get_player_type(definition) {
    # awaits something like: Rounds[2]["D"][10]["VA36"] as definition
    split(definition, splitted_def, "[")
    gsub("\"", "", splitted_def[3])
    gsub("]", "", splitted_def[3])
    return splitted_def[3]
}

function get_player_id(definition) {
    split(definition, splitted_def, "[")
    gsub("]", "", splitted_def[4])
    return splitted_def[4]
}

function get_player(line) {
    split(line, splitted_line, "=")
    player_type = get_player_type(splitted_line[1])
    player_id = get_player_id(splitted_line[1])

    gsub("\"", "", splitted_line[2])
    gsub(";", "", splitted_line[2])
    player_name = splitted_line[2]
    
    if (player_type == "D") {
        defenders[player_id] = player_name
    }
    else if (player_type == "A") {
        attackers[player_id] = player_name
    }
    else {
        print "UNHANDLED PLAYER TYPE " player_type
        exit
    }
}

function define_next_round_pattern(current_round) {
    next_round_pattern = "Rounds[" current_round + 1 "]=new Array();"
}

function get_ship_id(definition) {
    split(definition, splitted_def, "[")
    gsub("\"", "", splitted_def[5])
    gsub("]", "", splitted_def[5])
    return splitted_def[5]
}

function get_ship(line) {
    # get_ship_name
    split(line, splitted_line, "=")
    gsub("\"", "", splitted_line[2])
    split(splitted_line[2], ship_desc, "<")
    ship_name = ship_desc[1]

    # get ship id
    ship_id = get_ship_id(splitted_line[1])
    ship_list[ship_id] = ship_name
}

function get_initial_quantity(line) {
    split(line, splitted_line, "=")
    ship_id = get_ship_id(splitted_line[1])
    player_id = get_player_id(splitted_line[1])
    gsub("\"", "", splitted_line[2])
    gsub(";", "", splitted_line[2])
    quantity = splitted_line[2]
    player_type = get_player_type(splitted_line[1])
    if (player_type == "D") {
        initial_quantities[player_type, defenders[player_id], ship_id] = quantity
    } else {
        initial_quantities[player_type, attackers[player_id], ship_id] = quantity
    }
}

function get_ship_qtt(line) {
    split(line, splitted_line, "=")
    ship_id = get_ship_id(splitted_line[1])
    player_id = get_player_id(splitted_line[1])
    gsub("\"", "", splitted_line[2])
    gsub(";", "", splitted_line[2])
    quantity = splitted_line[2]
    player_type = get_player_type(splitted_line[1])
    if (player_type == "D") {
        current_quantities[player_type, defenders[player_id], ship_id] = quantity
    } else {
        current_quantities[player_type, attackers[player_id], ship_id] = quantity
    }
}

function get_object_loot(line) {
    regex = "> [0-9]{1,5} [éàa-zA-Z0-9\-]{1,}( [éàa-zA-Z0-9\-]{1,})*<"
    data_source = line
    where = match(data_source, regex)
    while(where != 0) {
        if (where == 0) {
            print "expecting value for " key ". Stop"
            exit 1
        } else {
            value = substr(data_source, RSTART, RLENGTH)
            gsub("<","", value)
            gsub(">","", value)
            gsub(",","", value)
            split(value, value_info, " ")
            qtt = 0
            object = ""
            for (i=0; i <= length(value_info); i++) {
                if (i == 1) {
                    qtt = value_info[i]
                } else if (i > 1) {
                    object = object " " value_info[i]
                }
            }
            object_loot[object] = qtt
            data_source = substr(data_source, where + RLENGTH, length(data_source) - where)
            where = match(data_source, regex)
        }
    }
    
}

{

    # check combat system version
    if (NR == 2) {
        if ($2 != expected_version) {
            print "Version found: "$2"|Version expected: " expected_version "| Error, stopping"
            exit 1
        }

    }

    # get player list
    if (round == 0) {
        if (index($1, "Pseudo") != 0) {
            get_player($0)
        }
    }

    # get ships name
    # get initial quantity
    else if (round == 1) {
        if (index($1, "Caracs") != 0 && $2 != "\"\";") {
            get_ship($0)
        }
    }
    # a fight being composed of at least 3 rounds, we have time
    # allows to not make naive processing too much
    else if (round == 2) {
        if (index($1, "[\"NbI\"]") != 0) {
            get_initial_quantity($0)
        }
    }
    # check loses (no marker to indicate final round, so naive thing we do is calculate each round)
    else if (round >= 3) {
        if (index($1, "[\"Nb\"]") != 0) {
            get_ship_qtt($0)
        }
    }

    if (match($3, "Events/Pillage.png") != 0 && index($1, "Rounds["round"][\"Events\"][event]") != 0) {
        get_object_loot($0)
    } 

    # defines quantity of resources captured
    if (index($1, "Rounds["round"][\"Events\"][event]") != 0 && match($4, "Victoire") && match($4, "attaquant")) {
        regex=">[0-9]{1,3}(,[0-9]{1,3})*<"
        data_source = $0
        resources[0] = ""
        resources[1] = ""
        resources[2] = ""
        for (key in resources) {
            where = match(data_source, regex)
            if (where == 0) {
                print "expecting value for " key ". Stop"
                exit 1
            } else {
                value = substr(data_source, RSTART, RLENGTH)
                gsub("<","", value)
                gsub(">","", value)
                gsub(",","", value)
                resources[key] = value
                data_source = substr(data_source, where + RLENGTH, length(data_source) - where)
            }
        }
    }

    # used to count victories
    if (index($1, "Rounds["round"][\"Events\"][event]") != 0 && match($3, "VictAtt.png")) {
        for (id in attackers) {
            if (combat_result["A", id, "Victoire(combat)"] == 0) {
                combat_result["A", id, "Victoire(combat)"] = 1
            } else {
                combat_result["A", id, "Victoire(combat)"] = combat_result["A", id, "Victoire(combat)"] + 1
            }
        }
        for (id in defenders) {
            if (combat_result["D", id, "Defaite(combat)"] == 0) {
                combat_result["D", id, "Defaite(combat)"] = 1
            } else {
                combat_result["D", id, "Defaite(combat)"] = combat_result["D", id, "Defaite(combat)"] + 1
            }
        }

    }

    # # used to count defeats
    if (index($1, "Rounds["round"][\"Events\"][event]") != 0 && match($3, "VictDef.png")) {
        for (id in defenders) {
            if (combat_result["D", id, "Victoire(combat)"] == 0) {
                combat_result["D", id, "Victoire(combat)"] = 1
            } else {
                combat_result["D", id, "Victoire(combat)"] = combat_result["D", id, "Victoire(combat)"] + 1
            }
        }
        for (id in attackers) {
            if (combat_result["A", id, "Defaite(combat)"] == 0) {
                combat_result["A", id, "Defaite(combat)"] = 1
            } else {
                combat_result["A," id, "Defaite(combat)"] = combat_result["A," id, "Defaite(combat)"] + 1
            }
        }
    }

    if (index($1, "Rounds["round"][\"Events\"][event]") != 0 && match($3, "BPExplo.png")) {
        split($4, destruction, "->")
        iindex = 1
        for (key in destruction) {
            if (iindex != 1) {
                gsub("<br/>", "",destruction[key])
                gsub("<br>", "",destruction[key])
                gsub(";", "",destruction[key])
                gsub("\"", "",destruction[key])
                gsub("\\.", "",destruction[key])
                gsub(" ont été ", "",destruction[key])
                # TODO regex to avoid multiple command
                gsub("détruites", "",destruction[key])
                gsub("détruite", "",destruction[key])
                gsub("détruits", "",destruction[key])
                gsub("détruit", "",destruction[key])
                gsub("^ ", "",destruction[key])
                split(destruction[key], destruction_info, " ")
                destruction_quantity = destruction_info[1]
                destruction_name = ""
                for (element in destruction_info) {
                    if (element != 1) {
                        destruction_name = destruction_name " " destruction_info[element]
                    }
                }
                gsub("^ ", "", destruction_name)
                if (combat_result["D", 1, destruction_name] == 0) {
                    combat_result["D", 1, destruction_name] = destruction_quantity
                } else {
                    combat_result["D", 1, destruction_name] = combat_result["D", 1, destruction_name] + destruction_quantity
                }
            }
            iindex = iindex + 1
        }
    }
    
    if (index($0, next_round_pattern) != 0) {
        round = round + 1
        define_next_round_pattern(round)
    }
}
END {
    for (id in attackers) {
        for (key in initial_quantities) {
            split(key, sub_keys, SUBSEP)
            player_type = sub_keys[1]
            player_name = sub_keys[2]
            ship_id = sub_keys[3]
            if (player_name == attackers[id] && player_type == "A") {
                lost = initial_quantities[key] - current_quantities[key]
                if (lost != 0) {
                    print attackers[id] "," ship_list[ship_id] "," lost
                }            
            }
        }
        for (key in combat_result) {
            split(key, sub_keys, SUBSEP)
            player_type = sub_keys[1]
            player_id = sub_keys[2]
            result_type = sub_keys[3]
            if (player_type == "A") {
                print attackers[player_id] "," result_type "," combat_result[key]
            }
        }
    }

    for (id in defenders) {
        for (key in initial_quantities) {
            split(key, sub_keys, SUBSEP)
            player_type = sub_keys[1]
            player_name = sub_keys[2]
            ship_id = sub_keys[3]
            if (player_name == defenders[id] && player_type == "D") {
                lost = initial_quantities[key] - current_quantities[key]
                if (lost != 0) {
                    print defenders[id] "," ship_list[ship_id] "," lost
                }
            }
        }
        for (key in combat_result) {
            split(key, sub_keys, SUBSEP)
            player_type = sub_keys[1]
            player_id = sub_keys[2]
            result_type = sub_keys[3]
            if (player_type == "D") {
                print defenders[player_id] "," result_type "," combat_result[key]
            }
        }
    }
    for (key in resources) {
        if (key == 0) {
            resource = "Métal"
        } else if (key == 1) {
            resource = "Tritium"
        } else if (key == 2) {
            resource = "Photopile"
        }
        print defenders[1] "," resource "," resources[key]
    }

    for (key in object_loot) {
        print defenders[1] "," substr(key, 2) "," object_loot[key]
    }
}
