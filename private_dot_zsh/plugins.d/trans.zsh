# sed removes hyphenations and join lines
#   \u2010 vs \u2D == ‐ vs - == "hyphen" vs "hyphen-minus"
#   A standard hyphen entered via keyboard is "hyphen-minus"
trans.stdin() { [[ -p /dev/stdin ]] && command cat || clippaste; }
trans.join_and_trim() { tr -d '\n' | tr -s '[:space:]' | sed "s/$(printf '\u2010') //g"; }
trans.e2j() { command trans -b -s en -t ja; }
trans.j2e() { command trans -b -s ja -t en; }

e2j() { trans.stdin | trans.join_and_trim | trans.e2j; }
j2e() { trans.stdin | trans.join_and_trim | trans.j2e; }

e2j2e() { e2j | tee >(trans.j2e); }
j2e2j() { j2e | tee >(trans.e2j); }
