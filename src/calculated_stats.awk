BEGIN {
    FS = ","
}

{
    if (count[$1, $2] == "") {
        count[$1, $2] = $3
    } else {
        count[$1, $2] = count[$1, $2] + $3
    }

    if (ships[$2] != "") {
        ships[$2] = $2
    }

    if (players[$1] != "") {
        players[$1] = $1
    }

}

END {
    for (player in players) {
        print " - " player
        for (ship in ships) {
            if (count[player, ship] != "") {
                print "    " ship " : " count[player, ship]
            }
        }
    }
}