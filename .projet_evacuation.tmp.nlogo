extensions [array]

globals [
  nb_exits        ; le nombre de sorties
  nb-person       ; le nombre total de personnes
  total-durations ; la somme des temps d'évacuation des personnes
  total-distance  ; la somme des distances parcourues des personnes
]

patches-own [
  object      ; floor, stage, storage, pillar, merchant-stand, token-stand,
              ; soud-operator-stand, exit, wall, door
  exit-index  ; numéro de la sortie (de 0 à nb sorties - 1)
  exit-energy ; tableau contenant l'énergie de la case pour chaque sortie

  ; pcolor : black, dark blue, cyan, sky, magenta, lime, white, pink, orange, red

  ; plabel : plus petite exit-energie de la case
]

turtles-own [
  speed
  ;    - child : 0.72 + random-float 0.48 - 0.24
  ;    - adult : 1 + random-float 0.48 - 0.24
  ;    - senior : 0.64 + random-float 0.48 - 0.24
  ;    - disabled : 0.632 + random-float 0.512 - 0.256
  current-speed      ; le speed peut changer si accompagné
  category           ; adult, child, senior, disabled, staff
  travelled-distance ; distance parcourue depuis le début de la simulation
  chosen-exit-index  ; l'index de la sortie désiré
  my-teammate-ID     ; l'ID de l'accompagnant dans le cas où "with-assist" est on
]

to set-objects ; identifie chaque objet en fonction de la couleur et l'index des portes
  ask patches [
    set object "wall"                                                               ; par défaut, un patch est un mur
    if pcolor >= floor-color - 1 and floor-color + 1 >= pcolor [set object "floor"] ; les patchs floor
    if pcolor >= exit-color - 1 and exit-color + 1 >= pcolor [set object "door"]    ; les patchs door
    if pcolor >= wall-color - 1 and wall-color + 1 >= pcolor [set object "wall"]    ; les patchs wall
    if pcolor >= obstacle1-color - 1 and obstacle1-color + 1 >= pcolor [set object "storage"] ; les patchs obstacle1
    if pcolor >= obstacle2-color - 1 and obstacle2-color + 1 >= pcolor [set object "storage"] ; les patchs obstacle2
    if pcolor >= obstacle3-color - 1 and obstacle3-color + 1 >= pcolor [set object "storage"] ; les patchs obstacle3
                                                          ;set exit-energy 2000
    set exit-index -1                                     ; par défaut, les patchs ont un index d'exit de -1 (portes comprises)
  ]

  let current-index 0                                     ; accumulateur pour que chaque porte ait un index propre

  ; le code suivant permet d'attribuer aux portes un index spécifique
  ; un patch "door" voisins d'un autre patch "door" aura le même index que celui-ci

  while [any? patches with [object = "door" and exit-index = -1]] [  ; Tant qu'il y a des patches "door" non marqués
    ask one-of patches with [object = "door" and exit-index = -1] [
      set exit-index current-index                                   ; on modifie l'index du patch pour avoir current-index

      ; on propage l'index à tous les voisins adjacents de manière récursive
      let patches-to-check (patch-set self)                          ; définition d'un ensemble de patchs à vérifier
      let more-patches-to-check true                                 ; booléen permettant d'arrêter la boucle une fois terminé

      while [more-patches-to-check] [                                ; tant que certains voisins n'ont pas été vérifié
        set more-patches-to-check false                              ; on défini cette variable à false par défaut
        ask patches-to-check [                                       ; on regarde chaque patch dont il faut vérifier les voisins
          ask neighbors with [object = "door" and exit-index = -1] [ ; on vérifie s'il existe des voisins non marqués
            set exit-index current-index                             ; on modifie leur index
            set patches-to-check (patch-set patches-to-check self)   ; et on les ajoute à la liste des patchs à vérifier
            set more-patches-to-check true                           ; on souhaite continuer la boucle while
          ]
        ]
      ]

      set current-index current-index + 1                            ; tous les patchs ont été vérifiés, on passe à l'index suivant
    ]
  ]
  set nb_exits current-index

end


to clear-energy ; réinitialise l'exit-energy de chaque patch à 1000 et supprime le label
  ask patches with [object = "floor" or object = "door"] [
    set exit-energy array:from-list n-values nb_exits [1000]
    set plabel ""
  ]
end

to setup-energy ; calcule l'énergie de chaque patch en partant des portes
  foreach n-values nb_exits [i -> i] [ n -> ; on définit l'exit energy de chaque exit
    ask patches with [object = "door"] [    ; on calcule l'exit energy en partant de chaque exit
      ifelse exit-index = n                 ; dans le cas où l'exit est celle dont on calcule l'exit energy :
      [compute-energy 0 self n]             ; on définit son énergie à 0 et on transmet l'énergie à ses voisins
      [compute-energy 1000 self n]          ; sinon on définit son énergie à 1000 (pour la sortie n)
    ]
  ]
end

to compute-energy [energy-level floor-patch index] ; attribue, en fonction de energy-level, l'énergie du patch et de ses voisins
  (ifelse
    object = "door"  [ array:set exit-energy index energy-level ]                    ; si le patch est une porte, on défini son énergie comme 'energy-level'
    object = "floor" [ array:set exit-energy index energy-level + distance myself ]  ; si c'est un 'floor', on défini son énergie comme l'énergie en entrée + la distance parcourue
    [])

  ask neighbors with [ object = "floor" and (array:item exit-energy index) > [array:item exit-energy index] of myself + distance myself ] [ ; si un voisin a une exit energy trop elevlée par rapport à celle du patch actuel
    compute-energy [array:item exit-energy index] of myself self index                                                                      ; on recalcule son énergie et on vérifie ses voisins
  ]
end

to set-plabel ; affiche l'exit-energie minimale de chaque patch comme label
  ask patches with [object = "floor"] [
    set plabel precision min array:to-list exit-energy 1
    set plabel-color white
  ]
end

to-report index-min [arr]         ; trouve l'index de la valeur minimale de arr
  let min-value array:item arr 0  ; initialise la valeur minimale avec le premier élément du tableau
  let min-index 0                 ; initialise l'index de la valeur minimale avec 0

  ; parcourt le tableau pour trouver la valeur minimale et son index
  let n array:length arr
  let i 1
  while [i < n] [
    let value array:item arr i
    if value < min-value [
      set min-value value
      set min-index i
    ]
    set i i + 1
  ]

  report min-index                ; Retourne l'index de la valeur minimale
end

to-report choose-wrong-exit [closest-exit] ; renvoie un nombre aléatoire dans l'ensemble [0 ; length arr] \ {colsest-exit}
  let index 0                                     ; on initialise index (le conetenue de index changera dans les 3 prochaines lignes
  set index random (array:length exit-energy - 1) ; choisit un index aléatoire du tableau arr (moins le dernier élément pour réajuster si besoin avec le if qui suit)
  if index >= closest-exit
  [set index index + 1]                           ; si nécessaire, on décale index de 1 pour retirer closest-exit des index possibles
  report index                                    ; on renvoie l'index
end

to create-adult ; créé un adult sur le patch actuel
  sprout 1 [
    set category "adult"
    set speed 1 + random-float 0.48 - 0.24
    set current-speed speed
    set travelled-distance 0
    set my-teammate-ID -1

    let chance-choose-wrong-exit random 100                                    ; génère une probabilité pour que la personne choisisse la sortie la plus proche
    ifelse chance-choose-wrong-exit > %-participant-choosing-the-colsest-exit  ; si le nombre généré est suppérieur à un certain seuil
    [set chosen-exit-index (choose-wrong-exit index-min exit-energy)]          ; le cas où une sortie qui n'est pas la plus proche est choisie
    [set chosen-exit-index (index-min exit-energy)]                            ; le cas où la sortie la plus proche est choisie

    set color yellow
    set shape "circle"
    if display-path [pen-down]
    set nb-person nb-person + 1
  ]
end

to create-child ; créé un child sur le patch actuel
  sprout 1 [
    set category "child"
    set speed 0.72 + random-float 0.48 - 0.24
    set current-speed speed
    set travelled-distance 0
    set my-teammate-ID -1

    let chance-choose-wrong-exit random 100                                    ; génère une probabilité pour que la personne choisisse la sortie la plus proche
    ifelse chance-choose-wrong-exit > %-participant-choosing-the-colsest-exit  ; si le nombre généré est suppérieur à un certain seuil
    [set chosen-exit-index (choose-wrong-exit index-min exit-energy)]          ; le cas où une sortie qui n'est pas la plus proche est choisie
    [set chosen-exit-index (index-min exit-energy)]                            ; le cas où la sortie la plus proche est choisie

    set color green
    set shape "circle"
    if display-path [pen-down]
    set nb-person nb-person + 1
  ]
end

to create-senior ; créé un senior sur le patch actuel
  sprout 1 [
    set category "senior"
    set speed 0.64 + random-float 0.48 - 0.24
    set current-speed speed
    set travelled-distance 0
    set my-teammate-ID -1

    let chance-choose-wrong-exit random 100                                    ; génère une probabilité pour que la personne choisisse la sortie la plus proche
    ifelse chance-choose-wrong-exit > %-participant-choosing-the-colsest-exit  ; si le nombre généré est suppérieur à un certain seuil
    [set chosen-exit-index (choose-wrong-exit index-min exit-energy)]          ; le cas où une sortie qui n'est pas la plus proche est choisie
    [set chosen-exit-index (index-min exit-energy)]                            ; le cas où la sortie la plus proche est choisie

    set color grey
    set shape "circle"
    if display-path [pen-down]
    set nb-person nb-person + 1
  ]
end

to create-disabled ; créé un disabled sur le patch actuel
  sprout 1 [
    set category "disabled"
    set speed 0.632 + random-float 0.512 - 0.256
    set current-speed speed
    set travelled-distance 0
    set my-teammate-ID -1

    let chance-choose-wrong-exit random 100                                    ; génère une probabilité pour que la personne choisisse la sortie la plus proche
    ifelse chance-choose-wrong-exit > %-participant-choosing-the-colsest-exit  ; si le nombre généré est suppérieur à un certain seuil
    [set chosen-exit-index (choose-wrong-exit index-min exit-energy)]          ; le cas où une sortie qui n'est pas la plus proche est choisie
    [set chosen-exit-index (index-min exit-energy)]                            ; le cas où la sortie la plus proche est choisie

    set color red
    set shape "circle"
    if display-path [pen-down]
    set nb-person nb-person + 1
  ]
end

to create-staff ; créé un staff sur le patch actuel
  sprout 1 [
    set category "staff"
    set speed 1 + random-float 0.48 - 0.24
    set current-speed speed
    set travelled-distance 0
    set my-teammate-ID -1

    let chance-choose-wrong-exit random 100                                    ; génère une probabilité pour que la personne choisisse la sortie la plus proche
    ifelse chance-choose-wrong-exit > %-participant-choosing-the-colsest-exit  ; si le nombre généré est suppérieur à un certain seuil
    [set chosen-exit-index (choose-wrong-exit index-min exit-energy)]          ; le cas où une sortie qui n'est pas la plus proche est choisie
    [set chosen-exit-index (index-min exit-energy)]                            ; le cas où la sortie la plus proche est choisie

    set color cyan
    set shape "circle"
    if display-path [pen-down]
    set nb-person nb-person + 1
  ]
end

to create-person-with-assist [p-category]  ; créé une personne assistée (child ou disabled)
  sprout 1 [
    set category p-category
    ifelse p-category = "child"
    [set speed 0.72 + random-float 0.48 - 0.24]       ; cas child
    [set speed 0.632 + random-float 0.512 - 0.256]    ; cas disabled
    set travelled-distance 0                          ; à sa création, une personne n'a pas parcouru de distance

    let chance-choose-wrong-exit random 100                                    ; génère une probabilité pour que la personne choisisse la sortie la plus proche
    ifelse chance-choose-wrong-exit > %-participant-choosing-the-colsest-exit  ; si le nombre généré est suppérieur à un certain seuil
    [set chosen-exit-index (choose-wrong-exit index-min exit-energy)]          ; le cas où une sortie qui n'est pas la plus proche est choisie
    [set chosen-exit-index (index-min exit-energy)]                            ; le cas où la sortie la plus proche est choisie

    let free-neighbors neighbors with [object = "floor" and not any? turtles-here and is-within-bounds?]  ; vérifie si un patch est disponible pour ajouter l'assistant

    if not any? free-neighbors
    [
      show (word "Error while creating assisted child, no room available for an adult")  ; si ce n'est pas le cas, levée d'une erreur
      stop
    ]

    ; on garde les informations essentielles pour les transmettre à l'assistant
    let person-chosen-index chosen-exit-index
    let adult-speed 1 + random-float 0.48 - 0.24
    let med-speed (adult-speed + speed) / 2
    let person-id who                             ; l'ID de l'assisté
    let adult-id -1

    ask one-of free-neighbors [ ; création de l'assistant (adult) sur la case voisine libre
      sprout 1 [
        set adult-id who
        set category "adult"
        set speed adult-speed
        set current-speed med-speed
        set travelled-distance 0
        set my-teammate-ID person-id
        set chosen-exit-index person-chosen-index

        set color yellow
        set shape "circle"
        if display-path [pen-down]
        set nb-person nb-person + 1
      ]
    ]

    set current-speed med-speed
    set my-teammate-ID adult-id

    ifelse p-category = "child"
    [set color green]
    [set color red]
    set shape "circle"
    if display-path [pen-down]
    set nb-person nb-person + 1
  ]
end

to-report is-within-bounds?
  report (pxcor >= x-min and pxcor <= x-max and pycor >= y-min and pycor <= y-max)
end

to create-person [num p-category] ; créé des personnes et les places sur la carte
  ; ------------------------- Cas with-assist = true -------------------------------
  ifelse with-assist and (p-category = "child" or p-category = "disabled")
  [
    let n 0                           ; accumulateur pour la boucle
    let free-patches patches with [object = "floor" and not any? turtles-here and is-within-bounds? and any? neighbors with [object = "floor" and not any? turtles-here and is-within-bounds?]]
    if count free-patches < 2 * num   ; 2 * num car on créé  2 personnes (l'assisté et l'assistant)
    [
      show (word "Not enough free floor patches to create " num " " p-category " with their helping adult.") ; sinon on envoie un message d'erreur
      stop
    ]
    while [n < num]                   ; on utiliser une boucle plutôt que n-num car le fait d'ajouter une personne en plus sur un des voisins peu poser problème si c'est en parallèle
    [
      if count free-patches = 0       ; vérifie le nombre de patchs disponibles (libre + voisin libre)
      [
        show (word "Not enough free floor patches to create " num " " p-category " with their helping adult.") ; sinon on envoie un message d'erreur
        stop
      ]
      ask n-of 1 free-patches [       ; choisit un des patchs libres avec un voisin libre aléatoirement
        create-person-with-assist p-category ; y ajoute un assisté et un assistant
      ]
      ; recalcule les patchs disponibles et valides
      set free-patches patches with [object = "floor" and not any? turtles-here and is-within-bounds? and any? neighbors with [object = "floor" and not any? turtles-here and is-within-bounds?]]
      set n n + 1                     ; incrémente l'accumulateur de la boucle
    ]
  ]
  ; ------------------------- Cas with-assist = false -------------------------------
  [
    let free-patches patches with [object = "floor" and is-within-bounds? and not any? turtles-here] ; récupère les patchs libres
    ifelse count free-patches >= num [                                         ; si il y a plus de patchs libres que de personnes à placer
      ask n-of num free-patches [                                              ; on sélectionne num patchs libres et on place les personnes
        if p-category = "adult" [
          create-adult
        ]
        if p-category = "child" [
          create-child
        ]
        if p-category = "senior" [
          create-senior
        ]
        if p-category = "disabled" [
          create-disabled
        ]
        if p-category = "staff" [
          create-staff
        ]
      ]
    ] [
      show (word "Not enough free floor patches to create " num " " p-category " turtles.") ; sinon on envoie un message d'erreur
    ]
  ]
end

to setup ; setup la simulation
  set-objects
  clear-energy
  setup-energy
  if display-energy [ set-plabel ]
end

to setup-person
  clear-turtles      ; on supprime les personnes
  clear-drawing      ; on supprime leur chemins
  clear-all-plots    ; on réinitialise le graphique
  set nb-person 0    ; réinitialise le nombre de personnes à 0
  set total-durations 0 ; réinitialise le temps total d'évacuation à 0
  set total-distance 0  ; réinitialise la distance totale parcourue à 0

  ifelse %-children + %-seniors + %-disabled > 100                    ; on vérifie si les pourcentages sont possibles
  [show (word "Error, the sum of percentage is above 100")]
  [
    create-person no-of-participants * ( %-children / 100) "child"                               ; on créé les child
    create-person no-of-participants * ( %-seniors / 100) "senior"                               ; on créé les senior
    create-person no-of-participants * ( %-disabled / 100) "disabled"                            ; on créé les disabled
    ifelse with-assist
    [create-person no-of-participants * (1 - (2 * %-children + %-seniors + 2 * %-disabled) / 100) "adult"] ; on créé les adult en prenant en compte les adult créé avec with-assist
    [create-person no-of-participants * (1 - (%-children + %-seniors + %-disabled) / 100) "adult"] ; on créé les adult
  ]
  reset-ticks
end

to move ; fait avancer la personne
  let min-energy 2000                     ; l'énergie minimale est initialisée à une valeur très grande
  let turtle-exit-index chosen-exit-index ; on garde l'index de la sortie voulue
  let target-patch nobody                 ; le patch vers lequel on veut se diriger

  ask patch-here [                                                     ; pour le patch sur lequel se trouve la personne
    ask other neighbors with [(object = "floor" or object = "door")] [ ; on demande à ses voisins sur lesquels on peut se déplacer
      if (array:item exit-energy turtle-exit-index < min-energy) and (not any? turtles-here) [ ; si ça nous rapproche de la sortie
        set min-energy array:item exit-energy turtle-exit-index        ; on garde la valeur d'énergie du patch
        set target-patch self                                          ; ainsi que le patch lui-même
      ]
    ]
  ]
  if target-patch != nobody [                                  ; si un patch nous rapproche de la sortie et est disponible
    face target-patch                                          ; on regarde vers celui-ci
    fd current-speed                                           ; et on s'y dirrige à notre vitesse
    set travelled-distance travelled-distance + current-speed  ; on augmente la distance parcourue totale
    set total-distance total-distance + current-speed          ; on ajoute sa distance parcourue à la distance totale
  ]

  if [object] of patch-here = "door" [          ; si la personne à atteint une porte
    set total-durations total-durations + ticks ; on garde le temps qu'elle a mis pour évacuer en ticks
    die                                         ; elle sort de la simulation
  ]
end

to go ; démarre la simulation
  go-once
  if not any? turtles [ ; s'il n'y a plus personne, on arrête la simulation
    show "No more turtles. Stopping the simulation."
    stop
  ]
end

to go-once ; fait un tick dans la simulation
  ask turtles [
    move
  ]
  tick
end

to place-staff ; place une personne de categorie "staff" là où clique l'utilisateur
  if mouse-down? [                                  ; lorsque l'utilisateur clique
    ask patch mouse-xcor mouse-ycor [               ; sur le patch où se situe la souris
      if not any? turtles-here and object = "floor" ; si le patch peut avoir une personne
      [create-staff]                                ; place u
    ]
  ]
end

to remove-person ; supprime la personne sur laquelle clique l'utilisateur
  if mouse-down? [                    ; lorsque l'utilisateur clique
    ask patch mouse-xcor mouse-ycor [ ; sur le patch où se situe la souris
      ask turtles-here [              ; demande aux personnes présentes
        if my-teammate-ID != -1 [     ; si elles ont une personne associée
          ask turtle my-teammate-ID [
            die                       ; tue cette personne
            set nb-person nb-person - 1 ; la retire du nombre de personnes dans la simulation
          ]
        ]
        die                           ; tue la personne sur laquelle l'utilisateur a cliqué
        set nb-person nb-person - 1   ; la retire du nombre de personnes dans la simulation
      ]
    ]
  ]
end

to draw ; colore le patch sur laquelle clique l'utilisateur en la couleur de draw-color
  if mouse-down? [                    ; lorsque l'utilisateur clique
    ask patch mouse-xcor mouse-ycor [ ; sur le patch où se situe la souris
      set pcolor draw-color           ; colore le patch en la couleur de draw-color
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
680
26
1871
698
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
90
0
50
0
0
1
ticks
30.0

SWITCH
192
40
315
73
display-energy
display-energy
1
1
-1000

BUTTON
2
77
98
110
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
2
40
98
74
NIL
setup-person
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
3
169
315
202
no-of-participants
no-of-participants
1
2000
2000.0
1
1
participants
HORIZONTAL

SLIDER
4
208
315
241
%-children
%-children
0
100
19.0
1
1
%
HORIZONTAL

SLIDER
5
247
315
280
%-disabled
%-disabled
0
10
2.8
0.1
1
%
HORIZONTAL

SLIDER
5
285
315
318
%-seniors
%-seniors
0
100
17.0
1
1
%
HORIZONTAL

BUTTON
103
40
187
73
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
192
77
316
110
display-path
display-path
0
1
-1000

PLOT
8
411
584
652
People to evacuate based on their categories
ticks
no-of-person
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"adult" 1.0 0 -1184463 true "" "plot count turtles with [category = \"adult\"]"
"child" 1.0 0 -13840069 true "" "plot count turtles with [category = \"child\"]"
"senior" 1.0 0 -7500403 true "" "plot count turtles with [category = \"senior\"]"
"disabled" 1.0 0 -2674135 true "" "plot count turtles with [category = \"disabled\"]"
"staff" 1.0 0 -11221820 true "" "plot count turtles with [category = \"staff\"]"

BUTTON
102
77
187
110
NIL
go-once
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
323
314
356
%-participant-choosing-the-colsest-exit
%-participant-choosing-the-colsest-exit
0
100
100.0
1
1
%
HORIZONTAL

SWITCH
192
132
315
165
with-assist
with-assist
0
1
-1000

INPUTBOX
329
40
484
100
floor-color
0.0
1
0
Color

INPUTBOX
329
108
484
168
wall-color
9.9
1
0
Color

INPUTBOX
330
176
485
236
exit-color
65.0
1
0
Color

INPUTBOX
494
40
649
100
obstacle1-color
15.0
1
0
Color

INPUTBOX
494
108
649
168
obstacle2-color
126.0
1
0
Color

INPUTBOX
495
176
650
236
obstacle3-color
95.0
1
0
Color

MONITOR
590
412
673
457
No. Adults
count turtles with [category = \"adult\"]
17
1
11

MONITOR
590
461
672
506
No. Children
count turtles with [category = \"child\"]
17
1
11

MONITOR
590
607
671
652
No. Staff
count turtles with [category = \"staff\"]
17
1
11

MONITOR
590
510
672
555
No. Seniors
count turtles with [category = \"senior\"]
17
1
11

MONITOR
590
559
672
604
No. Disabled
count turtles with [category = \"disabled\"]
17
1
11

BUTTON
7
362
162
395
NIL
place-staff
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
170
362
315
395
NIL
remove-person 
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
330
334
485
394
draw-color
0.0
1
0
Color

BUTTON
495
334
650
394
NIL
draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
10
658
107
703
Duration (ticks)
ticks
6
1
11

MONITOR
240
658
329
703
Avg. distance
total-distance / nb-person
6
1
11

MONITOR
110
658
237
703
Avg. Duration (ticks)
total-durations / nb-person
6
1
11

MONITOR
10
706
107
751
Duration (s)
ticks / 0.4
6
1
11

MONITOR
111
706
237
751
Avg. Duration (s)
(total-durations / nb-person) / 0.4
6
1
11

INPUTBOX
330
252
404
312
x-min
24.0
1
0
Number

INPUTBOX
411
252
485
312
x-max
90.0
1
0
Number

INPUTBOX
494
252
568
312
y-min
2.0
1
0
Number

INPUTBOX
574
252
650
312
y-max
48.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
