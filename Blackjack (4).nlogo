globals [deck house-money card-count true-count]

breed [dealers dealer]
breed [players player]
breed [cards card]
breed [in-hands in-hand]
breed [unknown-hands unknown-hand]
breed [discard-cards discard-card]
breed [second-cards second-card]

players-own [hand hand-value money bet-unit second-value]
dealers-own [hand hand-value shown-value]
cards-own [value count-value hidden-value]
in-hands-own [value count-value hidden-value]
unknown-hands-own [value count-value hidden-value]
discard-cards-own [value count-value hidden-value]
second-cards-own [value count-value hidden-value]

to setup
  ca
  reset-ticks
  ask patches [set pcolor green]
  set house-money 0

  create-players 3
  [
    set size 5
    set shape "person"
    set color black
    set money 0
    set bet-unit 1
    ask player 0
    [
      setxy 10 -16
      set label "Normal"
    ]
    ask player 1
    [
      setxy 0 -16
      set label "Advance"
    ]
    ask player 2
    [
      setxy -10 -16
      set label "Counting"
    ]
  ]
  create-dealers 1
  [
    set size 5
    set shape "person"
    set color black
    setxy 0 16
    set label "Dealer"
  ]

  generate-deck

  ask in-hands
  [
    set size 2
    set shape "square"
    set color white
    set hidden-value value
  ]

  ask unknown-hands
  [
    set size 2
    set shape "square"
    set color white
    set hidden-value 0
  ]

  ask discard-cards
  [
    set size 2
    set shape "square"
    set color white
  ]

end

to play
  tick
  repeat number-of-rounds
  [
    deal
    hand-total
    known-total
    check-blackjack
    ask player 0
    [
      normal-strat
    ]
    ask player 1
    [
      advance-strat
    ]
    ask player 2
    [
      if number-of-decks = 1 and card-count > 1
      [counting-strat]
      if number-of-decks > 1 and true-count > 1
      [counting-strat]
    ]
    ask dealer 3
    [
      dealer-strat
    ]
    choose-winners
    discard
  ]
end

to play-once
  tick
  ask player 0
  [
    normal-strat
  ]
  ask player 1
  [
    advance-strat
  ]
  ask player 2
  [
    if number-of-decks = 1 and card-count > 1
    [counting-strat]
    if number-of-decks > 1 and true-count > 1
    [counting-strat]
  ]
  ask dealer 3
  [
    dealer-strat
  ]
  choose-winners
end

to deal
  reshuffle
  count-cards
  ask player 2
  [
    if number-of-decks = 1 and card-count > 1
    [set bet-unit (card-count - 1) * bet-unit]
    if number-of-decks > 1 and true-count > 1
    [set bet-unit (true-count - 1) * bet-unit]
    if number-of-decks = 1 and card-count <= 1
    [set bet-unit 0]
    if number-of-decks > 1 and true-count <= 1
    [set bet-unit 0]
  ]
  repeat 2
  [
    ask player 0
    [
      ask one-of cards
      [
        create-link-to player 0
        set breed in-hands
        set shape "square"
        ifelse not any? turtles-on patch 11 -12
        [setxy 11 -12]
        [setxy 9 -12]
      ]
    ]
    ask player 1
    [
      ask one-of cards
      [
        create-link-to player 1
        set breed in-hands
        set shape "square"
        ifelse not any? turtles-on patch 1 -12
        [setxy 1 -12]
        [setxy -1 -12]
      ]
    ]
    ask player 2
    [
      if number-of-decks = 1 and card-count > 1
      [
        ask one-of cards
        [
          create-link-to player 2
          set breed in-hands
          set shape "square"
          ifelse not any? turtles-on patch -11 -12
          [setxy -11 -12]
          [setxy -9 -12]
        ]
      ]
      if number-of-decks > 1 and true-count > 1
      [
        ask one-of cards
        [
          create-link-to player 2
          set breed in-hands
          set shape "square"
          ifelse not any? turtles-on patch -11 -12
          [setxy -11 -12]
          [setxy -9 -12]
        ]
      ]
    ]
  ]
  ask dealer 3
    [
      ask one-of cards
      [
        create-link-to dealer 3
        set breed in-hands
        set shape "square"
        set hidden-value value
        setxy 1 12
      ]
      ask one-of cards
      [
        create-link-to dealer 3
        set breed unknown-hands
        set shape "square"
        set hidden-value 0
        setxy -1 12
      ]
    ]
  hand-total
  known-total
  check-blackjack

end

to hand-total
  ask players
  [
    set hand-value (sum [value] of link-neighbors)
    if any? link-neighbors with [label = "A"]
    [
      let number-of-aces count link-neighbors with [label = "A"]
      repeat number-of-aces
      [ifelse hand-value > 21
      [set hand-value (hand-value - 10)]
      [set hand-value hand-value]
      ]
    ]
  ]
  ask dealers
  [
    set hand-value (sum [value] of link-neighbors)
    if any? link-neighbors with [label = "A"]
    [
      let number-of-aces count link-neighbors with [label = "A"]
      repeat number-of-aces
      [ifelse hand-value > 21
      [set hand-value (hand-value - 10)]
      [set hand-value hand-value]
      ]
    ]
  ]
end

to known-total
  ask dealers
  [
    set shown-value (sum [hidden-value] of link-neighbors)
  ]
end

to normal-strat
  if [hand-value] of dealer 3 != 21
  [
    while [hand-value < normal-strategy-cut-off-point]
    [hit-normal]
  ]

end

to advance-strat
  if [hand-value] of dealer 3 != 21
  [
    while [hand-value <= 7]
    [hit-advance]

    if [shown-value] of dealer 3 = 11
    [while [member? hand-value [8 9 10 11 12 13 14 15 16]]
      [hit-advance]]

    if [shown-value] of dealer 3 = 10
    [while [member? hand-value [8 9 10 12 13 14 15 16]]
      [hit-advance]
      while [member? hand-value [11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 9
    [while [member? hand-value [8 9 12 13 14 15 16]]
      [hit-advance]
      while [member? hand-value [10 11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 8
    [while [member? hand-value [8 9 12 13 14 15 16]]
      [hit-advance]
      while [member? hand-value [10 11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 7
    [while [member? hand-value [8 9 12 13 14 15 16]]
      [hit-advance]
      while [member? hand-value [10 11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 6
    [while [member? hand-value [8]]
      [hit-advance]
      while [member? hand-value [9 10 11]]
        [hit-advance
          double]]
    if [shown-value] of dealer 3 = 5
    [while [member? hand-value [8]]
      [hit-advance]
      while [member? hand-value [9 10 11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 4
    [while [member? hand-value [8]]
      [hit-advance]
      while [member? hand-value [9 10 11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 3
    [while [member? hand-value [8 12]]
      [hit-advance]
      while [member? hand-value [9 10 11]]
        [hit-advance
          double]]

    if [shown-value] of dealer 3 = 2
    [while [member? hand-value [8 12]]
      [hit-advance]
      while [member? hand-value [9 10 11]]
        [hit-advance
          double]]

    if hand-value > 16
    [stop]
  ]
end

to counting-strat
  if [hand-value] of dealer 3 != 21
  [
    while [hand-value <= 7]
    [hit-counting]

    if [shown-value] of dealer 3 = 11
    [while [member? hand-value [8 9 10 11 12 13 14 15 16]]
      [hit-counting]]

    if [shown-value] of dealer 3 = 10
    [while [member? hand-value [8 9 10 12 13 14 15 16]]
      [hit-counting]
      while [member? hand-value [11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 9
    [while [member? hand-value [8 9 12 13 14 15 16]]
      [hit-counting]
      while [member? hand-value [10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 8
    [while [member? hand-value [8 9 12 13 14 15 16]]
      [hit-counting]
      while [member? hand-value [10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 7
    [while [member? hand-value [8 9 12 13 14 15 16]]
      [hit-counting]
      while [member? hand-value [10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 6
    [while [member? hand-value [8]]
      [hit-counting]
      while [member? hand-value [9 10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 5
    [while [member? hand-value [8]]
      [hit-counting]
      while [member? hand-value [9 10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 4
    [while [member? hand-value [8]]
      [hit-counting]
      while [member? hand-value [9 10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 3
    [while [member? hand-value [8 12]]
      [hit-counting]
      while [member? hand-value [9 10 11]]
        [hit-counting
          double]]

    if [shown-value] of dealer 3 = 2
    [while [member? hand-value [8 12]]
      [hit-counting]
      while [member? hand-value [9 10 11]]
        [hit-counting
          double]]

    if hand-value > 16
    [stop]
  ]
end

to dealer-strat
  while [hand-value < 17]
  [hit-dealer]
end

to hit-normal
  ask player 0
  [
    ask one-of cards
    [
      create-link-to player 0
      set breed in-hands
      set shape "square"
      ifelse not any? turtles-on patch 11 -10
      [setxy 11 -10]
      [ifelse not any? turtles-on patch 9 -10
        [setxy 9 -10]
        [ifelse not any? turtles-on patch 11 -8
        [setxy 11 -8]
          [ifelse not any? turtles-on patch 9 -8
            [setxy 9 -8]
            [ifelse not any? turtles-on patch 11 -6
              [setxy 11 -6]
              [ifelse not any? turtles-on patch 9 -6
              [setxy 9 -6]
                [ifelse not any? turtles-on patch 11 -4
                  [setxy 11 -4]
                  [ifelse not any? turtles-on patch 9 -4
                    [setxy 9 -4]
                    [ifelse not any? turtles-on patch 11 -2
                      [setxy 11 -2]
                      [ifelse not any? turtles-on patch 9 -2
                        [setxy 9 -2]
                        [ifelse not any? turtles-on patch 11 0
                          [setxy 11 0]
                          [ifelse not any? turtles-on patch 9 0
                            [setxy 9 0]
                            [ifelse not any? turtles-on patch 11 2
                              [setxy 11 2]
                              [ifelse not any? turtles-on patch 9 2
                                [setxy 9 2]
                                [ifelse not any? turtles-on patch 13 -10
                                  [setxy 13 -10]
                                  [ifelse not any? turtles-on patch 13 -8
                                    [setxy 13 -8]
                                    [ifelse not any? turtles-on patch 13 -6
                                      [setxy 13 -6]
                                      [ifelse not any? turtles-on patch 13 -4
                                        [setxy 13 -4]
                                        [ifelse not any? turtles-on patch 13 -2
                                          [setxy 13 -2]
                                          [ifelse not any? turtles-on patch 13 0
                                            [setxy 13 0]
                                            [setxy 13 2]
                                          ]
                                        ]
                                      ]
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    hand-total
  ]
end

to hit-advance
  ask player 1
  [
    ask one-of cards
    [
      create-link-to player 1
      set breed in-hands
      set shape "square"
      ifelse not any? turtles-on patch 1 -10
      [setxy 1 -10]
      [ifelse not any? turtles-on patch -1 -10
        [setxy -1 -10]
        [ifelse not any? turtles-on patch 1 -8
          [setxy 1 -8]
          [ifelse not any? turtles-on patch -1 -8
            [setxy -1 -8]
            [ifelse not any? turtles-on patch 1 -6
              [setxy 1 -6]
              [ifelse not any? turtles-on patch -1 -6
              [setxy -1 -6]
                [ifelse not any? turtles-on patch 1 -4
                  [setxy 1 -4]
                  [ifelse not any? turtles-on patch -1 -4
                    [setxy -1 -4]
                    [ifelse not any? turtles-on patch 1 -2
                      [setxy 1 -2]
                      [ifelse not any? turtles-on patch -1 -2
                        [setxy -1 -2]
                        [ifelse not any? turtles-on patch 1 0
                          [setxy 1 0]
                          [ifelse not any? turtles-on patch -1 0
                            [setxy -1 0]
                            [ifelse not any? turtles-on patch 1 2
                              [setxy 1 2]
                              [ifelse not any? turtles-on patch -1 2
                                [setxy -1 2]
                                [ifelse not any? turtles-on patch 3 -10
                                  [setxy 3 -10]
                                  [ifelse not any? turtles-on patch 3 -8
                                    [setxy 3 -8]
                                    [ifelse not any? turtles-on patch 3 -6
                                      [setxy 3 -6]
                                      [ifelse not any? turtles-on patch 3 -4
                                        [setxy 3 -4]
                                        [ifelse not any? turtles-on patch 3 -2
                                          [setxy 3 -2]
                                          [ifelse not any? turtles-on patch 3 0
                                            [setxy 3 0]
                                            [setxy 3 2]
                                          ]
                                        ]
                                      ]
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    hand-total
  ]
end

to hit-counting
  ask player 2
  [
    ask one-of cards
    [
      create-link-to player 2
      set breed in-hands
      set shape "square"
      ifelse not any? turtles-on patch -11 -10
      [setxy -11 -10]
      [ifelse not any? turtles-on patch -9 -10
        [setxy -9 -10]
        [ifelse not any? turtles-on patch -11 -8
          [setxy -11 -8]
          [ifelse not any? turtles-on patch -9 -8
            [setxy -9 -8]
            [ifelse not any? turtles-on patch -11 -6
              [setxy -11 -6]
              [ifelse not any? turtles-on patch -9 -6
              [setxy -9 -6]
                [ifelse not any? turtles-on patch -11 -4
                  [setxy -11 -4]
                  [ifelse not any? turtles-on patch -9 -4
                    [setxy -9 -4]
                    [ifelse not any? turtles-on patch -11 -2
                      [setxy -11 -2]
                      [ifelse not any? turtles-on patch -9 -2
                        [setxy -9 -2]
                        [ifelse not any? turtles-on patch -11 0
                          [setxy -11 0]
                          [ifelse not any? turtles-on patch -9 0
                            [setxy -9 0]
                            [ifelse not any? turtles-on patch -11 2
                              [setxy -11 2]
                              [ifelse not any? turtles-on patch -9 2
                                [setxy -9 2]
                                [ifelse not any? turtles-on patch -13 -10
                                  [setxy -13 -10]
                                  [ifelse not any? turtles-on patch -13 -8
                                    [setxy -13 -8]
                                    [ifelse not any? turtles-on patch -13 -6
                                      [setxy -13 -6]
                                      [ifelse not any? turtles-on patch -13 -4
                                        [setxy -13 -4]
                                        [ifelse not any? turtles-on patch -13 -2
                                          [setxy -13 -2]
                                          [ifelse not any? turtles-on patch -13 0
                                            [setxy -13 0]
                                            [setxy -13 2]
                                          ]
                                        ]
                                      ]
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    hand-total
  ]
end

to hit-dealer
  ask dealer 3
  [
    ask one-of cards
    [
      create-link-to dealer 3
      set breed in-hands
      set shape "square"
      ifelse not any? turtles-on patch 1 10
      [setxy 1 10]
      [ifelse not any? turtles-on patch -1 10
        [setxy -1 10]
        [ifelse not any? turtles-on patch 1 8
          [setxy 1 8]
          [ifelse not any? turtles-on patch -1 8
            [setxy -1 8]
            [ifelse not any? turtles-on patch 1 6
              [setxy 1 6]
              [ifelse not any? turtles-on patch -1 6
              [setxy -1 6]
                [ifelse not any? turtles-on patch 1 4
                  [setxy 1 4]
                  [ifelse not any? turtles-on patch -1 4
                    [setxy -1 4]
                    [ifelse not any? turtles-on patch 3 10
                      [setxy 3 10]
                      [ifelse not any? turtles-on patch 3 8
                        [setxy 3 8]
                        [ifelse not any? turtles-on patch 3 6
                          [setxy 3 6]
                          [ifelse not any? turtles-on patch 3 4
                            [setxy 3 4]
                            [ifelse not any? turtles-on patch -3 10
                              [setxy -3 10]
                              [ifelse not any? turtles-on patch -3 8
                                [setxy -3 8]
                                [ifelse not any? turtles-on patch -3 6
                                  [setxy 3 6]
                                  [ifelse not any? turtles-on patch -3 4
                                    [setxy -3 4]
                                    [ifelse not any? turtles-on patch 5 10
                                      [setxy 5 10]
                                      [ifelse not any? turtles-on patch -5 10
                                        [setxy -5 10]
                                        [ifelse not any? turtles-on patch 5 8
                                          [setxy 5 8]
                                          [ifelse not any? turtles-on patch -5 8
                                            [setxy -5 8]
                                            [setxy 5 6]
                                          ]
                                        ]
                                      ]
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    hand-total
  ]
end

to check-blackjack
  if [hand-value] of dealer 3 = 21
  [
    ask dealer 3
    [
      ifelse [hand-value] of player 0 != 21 and [hand-value] of player 1 != 21 and [hand-value] of player 2 != 21
      [set house-money (house-money + [bet-unit] of player 0 + [bet-unit] of player 1 + [bet-unit] of player 2)]
      [ifelse [hand-value] of player 0 != 21 and [hand-value] of player 1 != 21
        [set house-money (house-money + [bet-unit] of player 0 + [bet-unit] of player 1)]
        [ifelse [hand-value] of player 0 != 21 and [hand-value] of player 2 != 21
          [set house-money (house-money + [bet-unit] of player 0 + [bet-unit] of player 2)]
          [ifelse [hand-value] of player 1 != 21 and [hand-value] of player 2 != 21
            [set house-money (house-money + [bet-unit] of player 1 + [bet-unit] of player 2)]
            [ifelse [hand-value] of player 0 != 21
              [set house-money (house-money + [bet-unit] of player 0)]
              [ifelse [hand-value] of player 1 != 21
                [set house-money (house-money + [bet-unit] of player 1)]
                [ifelse [hand-value] of player 2 != 21
                  [set house-money (house-money + [bet-unit] of player 2)]
                  [set house-money house-money]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    ask players
    [
      ifelse hand-value != 21
      [set money (money - bet-unit)]
      [set money money]
    ]
    ask players
    [
      set bet-unit 1
    ]
  ]

  if [hand-value] of player 0 = 21 and [hand-value] of dealer 3  != 21
  [
    ask player 0
    [
      set money (money + (1.5 * bet-unit))
      set house-money (house-money - (1.5 * bet-unit))
      set bet-unit 1
    ]
  ]
  if [hand-value] of player 1 = 21 and [hand-value] of dealer 3  != 21
  [
    ask player 1
    [
      set money (money + (1.5 * bet-unit))
      set house-money (house-money - (1.5 * bet-unit))
      set bet-unit 1
    ]
  ]
  if [hand-value] of player 2 = 21 and [hand-value] of dealer 3  != 21
  [
    ask player 2
    [
      set money (money + (1.5 * bet-unit))
      set house-money (house-money - (1.5 * bet-unit))
      set bet-unit 1
    ]
  ]
end

to choose-winners
  ask players
  [
    ifelse ([hand-value] of dealer 3 = 21) and (count [link-neighbors] of dealer 3 = 2)
    [set money money]
    [ifelse hand-value = 21 and count link-neighbors = 2
      [set money money]
      [ifelse hand-value > 21
        [bust]
        [ifelse hand-value = [hand-value] of dealer 3
          [set money money
            set house-money house-money]
          [ifelse hand-value > [hand-value] of dealer 3 or [hand-value] of dealer 3 > 21
            [set money (money + bet-unit)
              set house-money (house-money - bet-unit)]
            [set money (money - bet-unit)
              set house-money house-money + bet-unit]
          ]
        ]
      ]
    ]
    set bet-unit 1
  ]
end

to bust
    set money (money - bet-unit)
    set house-money (house-money + bet-unit)
end

to discard
  ask in-hands
  [
    set breed discard-cards
    set shape "square"
    set count-value count-value
    setxy 10 16
  ]
  ask unknown-hands
  [
    set breed discard-cards
    set shape "square"
    set count-value count-value
    setxy 10 16
  ]
  clear-links

end

to reshuffle

  if count cards <= 16
  [ask discard-cards
    [die]
    ask cards
    [die]
    generate-deck]

end

to generate-deck
  create-cards 4 * number-of-decks
  [
    set label "A"
    set value 11
    set count-value -1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 2
    set value 2
    set count-value 1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 3
    set value 3
    set count-value 1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 4
    set value 4
    set count-value 1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 5
    set value 5
    set count-value 1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 6
    set value 6
    set count-value 1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 7
    set value 7
    set count-value 0
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 8
    set value 8
    set count-value 0
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 9
    set value 9
    set count-value 0
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label 10
    set value 10
    set count-value -1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label "J"
    set value 10
    set count-value -1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label "Q"
    set value 10
    set count-value -1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
  create-cards 4 * number-of-decks
  [
    set label "K"
    set value 10
    set count-value -1
    set label-color black
    set size 2
    set shape "square"
    set color white
    setxy -10 16
  ]
end

to double

  set bet-unit (bet-unit * 2)
  stop

end

to count-cards

  set card-count sum [count-value] of discard-cards
  set true-count round ((sum [count-value] of discard-cards) / (count cards / 52))

end
@#$#@#$#@
GRAPHICS-WINDOW
345
10
700
366
-1
-1
7.1
1
10
1
1
1
0
0
0
1
-24
24
-24
24
0
0
1
ticks
30.0

BUTTON
56
129
141
162
NIL
play
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
34
40
100
73
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

SLIDER
15
183
187
216
number-of-decks
number-of-decks
1
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
208
110
314
155
Normal's Score
[hand-value] of player 0
17
1
11

MONITOR
207
160
321
205
Advance's Score
[hand-value] of player 1
17
1
11

MONITOR
207
210
322
255
Counting's Score
[hand-value] of player 2
17
1
11

MONITOR
208
13
316
58
Dealer's Score
[hand-value] of dealer 3
17
1
11

SLIDER
14
262
220
295
normal-strategy-cut-off-point
normal-strategy-cut-off-point
3
21
17.0
1
1
NIL
HORIZONTAL

MONITOR
208
63
334
108
Dealer's Known Card
[shown-value] of dealer 3
17
1
11

MONITOR
575
373
687
418
Normal's Money
[money] of player 0
17
1
11

MONITOR
465
373
571
418
Advance's Money
[money] of player 1
17
1
11

MONITOR
349
374
459
419
Counting's Money
[money] of player 2
17
1
11

MONITOR
466
424
570
469
House's Money
house-money
17
1
11

SLIDER
15
224
188
257
number-of-rounds
number-of-rounds
1
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
108
40
171
73
NIL
deal
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
9
87
103
120
NIL
play-once
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
112
87
190
120
NIL
discard
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
237
261
322
306
Card Count
sum [count-value] of discard-cards
17
1
11

MONITOR
240
312
323
357
True Count
round ((sum [count-value] of discard-cards) / (count cards / 52))
17
1
11

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
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Gains Over Time" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>play</go>
    <timeLimit steps="1"/>
    <metric>[money] of player 0</metric>
    <metric>[money] of player 1</metric>
    <metric>[money] of player 2</metric>
    <metric>house-money</metric>
    <enumeratedValueSet variable="number-of-rounds">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="normal-strategy-cut-off-point">
      <value value="17"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-decks" first="1" step="1" last="10"/>
  </experiment>
</experiments>
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
