BEGIN {
    FS = ","
}

{
    if (count[$1, $2] == "") {
        html_table_line_per_player[$1] = html_table_line_per_player[$1] + 1
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

function write_html_output() {
    current_player = ""
    rowspan = 0
    span_written = 0
    print "<table>"
    print "    <tr>"
    print "        <th>Joueur</th>"
    print "        <th>Element</th>"
    print "        <th>Quantite</th>"
    print "    </tr>"
    for (player in players) {
        for (ship in ships) {
            if (player != current_player) {
                current_player = player
                rowspan = 1
                span_written = 0
            } else {
                if (span_written == 1) {
                    rowspan = 0
                }
            }
            if (count[player, ship] != "") {
                if (rowspan == 1) {
                    print "    <td rowspan="html_table_line_per_player[player]">"player"</td>"
                }
                print "    <td>"ship"</td>"
                print "    <td>"count[player, ship]"</td>"
                print "</tr>"
                span_written = 1
            }
        }
    }
    print "</table>"
}

function write_list_output() {
    for (player in players) {
        print "- " player
        for (ship in ships) {
            if (count[player, ship] != "") {
                print "  - " ship " : " count[player, ship]
            }
        }
    }
}

END {
    if (output_style == "html") {
        write_html_output()
    } else {
        write_list_output()
    }

}