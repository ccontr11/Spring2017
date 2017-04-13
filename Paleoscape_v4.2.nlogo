extensions [ gis profiler ]
globals [
  vegetation                 ; input data of vegetation types for each patch
  cx cy                      ; xy coordinates of camp location, so agents can find their camp
  time_vt                    ; time spent in veg type (cumulative for all agents each day)
  tide                       ; keeps track of the tide; can be "poor" (most often), "OK" (8 days/month), or "good" (2 days/month)
  ;last-OK-tide              ; keeps track of when the last spring semi-low tides were (in terms of days passed)
  ;last-good-tide            ; keeps track of when the last spring low tide was (in terms of days passed)
  cum_kcal                   ; total kcal accumulated throughout simulation
  cum_km
  ;day                       ; counts which day we are on (same as 'ticks')
  ;newday                    ; boolean; 0=not new day, 1=new day
  ;time                      ; time that has passed during a day
  days-until-tide            ; days until next good tidal cycle
  tideday                    ; ranges from 0-14 over the tidal cycle, last 5 are springdays
  kcal_vt1
  kcal_vt2                   ; globals to keep track of kcal foraged in each vt
  kcal_vt3
  kcal_vt4
  kcal_vt5
  kcal_vt6
  kcal_vt8
  kcal_vt9
  kcal_vt10
  kcal_vt11
  kcal_vt12
  kcal_vt13
  kcal_vt14
  patches-vt
  patches-vt10
  patches-coast
  mean_dailykcal
  mean_dailykm
  time-walk-cell
  camp-mobility

  ; coast
  mult-undepl
  mult-repl
  mult-depl
  ;hunting
  success-rate              ; list of success rates for each species (doesn't vary per habitat)
  pursuit-time              ; list of pursuit times for each species
  prey_cal                  ; caloric return for each species, replaces weight
  prey_cal_stdev            ; stdev of caloric return for each species, to introduce variance in returns and better accord to input data
  nrspecies                 ; number of prey species
  rt-rate                   ; return rate for each species
  hunt-time                 ; time spend hunting different species
  meat_vt                   ; for each vegetation type the weight of animals caught
  hunters gathers           ; agentsets to hold each agent type. (like breed but more flexible)
  memoryfood                ; number of days the camps use to evaluate whether productivity of camp is sufficient to stay
  ]
patches-own [
  vt                        ; vegetation/coastal resource type
  kcal_return               ; original kcal/hr return rate for each patch  (includes coastal cell spring tide returns)
  kcal_return_min           ; same for terrestrial, but holds lower value for non-spring and non-low tides of coastal patches
  stdev_kcal_return         ; for giving variable returns based on mean/stdev inputs
  current_kcal_return       ; current kcal/hr return rate for each patch, under systematic-search-of-habitat assumption, is either vt-specific full or zero
  total-harvest-time        ; search/harvest time (hr/ha)           Varies from 0.63-17.9 hr/hectare. 17.9 is 3 or 4 person days worth of harvesting...
  pass-harvest-time         ; search/harvest time (hr/ha) to cross a patch once. Always total-time-harvest/5 since foragers cover a 20m wide swath of the 1ha cell
  ;time-foraged-here         ; counts time foraged from each habitat, so we know where foragers are spending their time
  ;kcal_foraged_here         ; counts kcal foraged from each habitat over time, so we know where their energy is coming from
  goodcoast?                ; boolean to exclude Sandy Beach from coastal foraging patches   ;should replace with a goodcoast patch-set
  time-until-replenished    ; veg replenishes after 365 days, counter gets reset to zero after each instance of harvesting (no half-patches replenishing at separtate times)
  times-harvested           ; alternative way to keep track of kcal extracted by vt, doesn't work for coastal cells....
  temporal_multiplier       ; strange piece of code to weigh the returns over the next days_of_foresight

  ;hunting vars, start the listyness
  encounter                 ; encounter rates, probability of encountering one of mammal list in N encounters / 100 m
  relencounter              ; relative population size?
  counted                   ; counter for the number of species checked in a patch during encounter procedure
  enc-dep                   ; encounter depression
  crowding                  ; number of agents passing through cell during that day affecting the encounter rates

  ]
breed [agents agent]
breed [camps camp]
agents-own [
  time-forage-budget        ; time an agent has left to forage
  time-foraged              ; time agent has foraged
  dailykcal                 ; total kcal foraged each day (updated throughout the day, cleared at end of day)
  done                      ; done for the day
  timecamp                  ; travel time between forager and camp
  dailykm
  campsite                  ; camp of the agent
  days_without

  ;hunting vars
  hg                        ; hunter or gatherer switch, val=h or val=g
  avgpastrr                 ; average return rates over last x days
  potmeat                   ; amount of meat (in kcal) caught during a pursuit
  pursuit                   ; boolean whether agent is in pursuit
  time-pursuit              ; time an agent was in a pursuit
]
camps-own [
  directions                ; list of directions of initial movements at the start of the day
  directioncamp             ; direction to which camp will move
  leftorright               ; randomly defined boolean whether agents go initially left or right to the camp at the start of the day
  kcal_per_day              ; total kcal accumulated each day
  hist_kcal_per_day         ; list of total kcal accumulated for the last x days
  kcal_total                ; total kcal accumulated throughout entire scenario
  overall_avg_kcal          ; mean kcal per agent per day
  timecoast                 ; camps track their distance to the coast, for use in mod-cog scenario
  coastal_target            ; the closest coastal patch to camp at any given time
  days_without              ; counter of days the camp brings in no calories
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Species list (taken from Jan Venter's list June 2016), would be great to import it all as a table/matrix/array
;Species ID  Species/habitat
;0  Black Rhino
;1  Black Wildebeest*
;2  Blue antelope
;3  Blue Duiker
;4  Bontebok*
;5  Bushbuck
;6  Bushpig
;7  Cape Buffalo*
;8  Cape dune molerat
;9  Cape hartebeest*
;10  Eland*
;11  Elephant*
;12  Greater kudu
;13  Grey Duiker
;14  Grysbok
;15  Hippo
;16  Klipspringer
;17  Mountain Reedbuck
;18  Mountain Zebra
;19  Oribi
;20  Quagga*
;21  Roan
;22  Rock hyrax
;23  Southern Reedbuck
;24  Springbok*
;25  Steinbok
;26  Vaalribbok
;27  Warthog


to setup
  ca
  reset-ticks

  ;; SEED FOR TESTING
  ;random-seed 1

  ;;*****SET UP VEGETATION*****
  ;; import dataset:  "data/chloe_final_abm_map_24nov14_test.asc"
  ifelse map-zone = "z1" OR map-zone = "z2" [
      set vegetation gis:load-dataset (word "data/allhab_1ha_" map-zone ".asc")
      resize-world 0 299 0 199 set-patch-size 1.75
  ]
  [ ; full size
      set vegetation gis:load-dataset "data/all_habitats_1ha.asc"
      resize-world 0 779 0 539 set-patch-size 0.65
  ]

  gis:set-world-envelope gis:envelope-of vegetation
  ;;  apply GIS data to vet types
  gis:apply-raster vegetation vt
  set patches-vt (patch-set patches with [vt > 0])
  set patches-coast (patch-set patches with [vt >= 10])
  set patches-vt10 (patch-set patches with [vt > 0 and vt < 10])

  ;; assign veg types initial kcal/hr return rates and harvest times
  ask patches-vt [
    if vt = 1  [set total-harvest-time 17.9   set kcal_return 2000]      ; Freshwater wetlands     ;made up value because result is just silly; 449 kg/ha Prionium * 21% edible, 1150 kcal / kg of palm hearts = ridiculous 87 779 kcal /ha, or 160 /kg for celery = 12 212 still ridiculous. So much time spent too.... not sure how to balance this
    if vt = 2  [set total-harvest-time 13.4   set kcal_return 1160]      ; Alluvial Vegetation     19 kg/ha Typha, 610 kcal / kg of leeks
    if vt = 3  [set total-harvest-time 1.17   set kcal_return 1200] ;1680]      ; Strandveld              8.4 kg/ha 2x sour figs * 40% edible, 500 kcal / kg of apple?
    if vt = 4  [set total-harvest-time 0.83   set kcal_return 0]      ; Saline Vegetation
    if vt = 5  [set total-harvest-time 0.67   set kcal_return 100]      ; Renosterveld
    if vt = 6  [set total-harvest-time 0.72   set kcal_return 1022]      ; Sand Fynbos              1.4 kg/ha Watsonia, 730 kcal / kg of jerusalem artichoke
    ;vt = 7 for wide scale? nope.
    if vt = 8  [set total-harvest-time 0.65   set kcal_return 100]      ; Thicket                   Safra seed pods
    if vt = 9  [set total-harvest-time 0.70   set kcal_return 468]     ; Limestone Fynbos           1.8 kg/ha sour fig * 52% edible, 500 kcal / kg of apple
    if vt = 10 [set total-harvest-time 1.5   set kcal_return 1450   set kcal_return_min 250]      ; Aeolianite (Coastal); the coastal rates here are "poor", the most common state
    if vt = 11 [set total-harvest-time 1.5   set kcal_return 150]      ; "Sandy Beach (Coastal); only coastal vt with a fixed return
    if vt = 12 [set total-harvest-time 1.5   set kcal_return 1100   set kcal_return_min 250]      ; "TMS Boulders (Coastal)
    if vt = 13 [set total-harvest-time 1.5   set kcal_return 1100   set kcal_return_min 250]      ; TMS Eroded Rocky Headlands (Coastal)
    if vt = 14 [set total-harvest-time 1.5   set kcal_return 1100   set kcal_return_min 250]      ; TMS Wave Cut Platforms (Coastal)

    ;test version with bumped coastal harvest rates
    ;if vt >= 10 [set kcal_return 2500]

    ifelse vt < 10 [set pass-harvest-time total-harvest-time / 5][set pass-harvest-time total-harvest-time / 3] ;5 passes needed for terrestrial, 3 passes needed for coastal (3 people deplete in 30 minutes)
    if kcal_return_min = 0 [set kcal_return_min kcal_return]         ; clone the reg return value for terrestrial patches for pick-patch-


    ;hunting vars for terrestrials - copied from Mammal Abundance Data - Paleoscape Model_JV_Prelim_June2016. Not right bc this is density not actually encounter prob. Need excel math from Buckland
    if vt = 1 [ set encounter (list
        0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0400  0.0222  0.0000  0.0000  0.0033  0.0000  0.0222  0.0020  0.0010  0.0182  0.0167  0.0018  0.0020  0.0000  0.0000  0.0000  0.0020
        )]
    if vt = 2 [ set encounter (list
        0.0033  0.0050  0.1250  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0400  0.0256  0.0000  0.0500  0.0033  0.0000  0.0000  0.0020  0.0010  0.0182  0.0167  0.0018  0.0020  0.0000  0.0000  0.0000  0.0020
        )]
    if vt = 3 [ set encounter (list
        0.0029  0.0021  0.0667  0.0029  0.0022  0.0002  0.0000  0.0003  0.0003  0.0000  0.0000  0.0007  0.0133  0.0039  0.0500  0.0000  0.0000  0.0333  0.0001  0.0003  0.0020  0.0015  0.0018  0.0000  2.0000  0.0000  0.0001  0.0001
        )]
    if vt = 4 [ set encounter (list
        0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0020  0.0000  0.0000  0.0000  0.0000
        )]
    if vt = 5 [ set encounter (list
        0.0022  0.0022  0.0000  0.0029  0.0049  0.0016  0.0001  0.0003  0.0003  0.0002  0.0007  0.0007  0.0133  0.0435  0.0033  0.0000  0.0003  0.0286  0.0010  0.0001  0.0020  0.0015  0.0015  0.0000  0.0000  0.0000  0.0000  0.0000
        )]
    if vt = 6 [ set encounter (list
        0.0032  0.0022  0.0000  0.0029  0.0002  0.0018  0.0002  0.0003  0.0003  0.0002  0.0004  0.0007  0.0133  0.0476  0.0476  0.0000  0.0003  0.0313  0.0001  0.0005  0.0018  0.0015  0.0017  0.0000  2.0000  0.0000  0.0001  0.0002
        )]
    if vt = 8 [ set encounter (list
        0.0003  0.0000  0.1250  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0039  0.0000  0.0007  0.0256  0.0625  0.0046  0.0000  0.0000  0.0417  0.0001  0.0004  0.0286  0.0167  0.0023  0.0000  0.0000  0.0000  0.0000  0.0020
        )]
    if vt = 9 [ set encounter (list
        0.0041  0.0018  0.0000  0.0029  0.0072  0.0018  0.0002  0.0003  0.0003  0.0027  0.0010  0.0004  0.0133  0.0455  0.0455  0.0000  0.0003  0.0303  0.0001  0.0001  0.0015  0.0015  0.0018  0.0000  2.0000  0.0000  0.0000  0.0001
        )]
    if vt >= 10 AND vt != 11 [ set encounter (list
        0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0003  0.0000  0.0000  0.1429  0.0007  0.0000  0.0000  0.0000  0.0000  0.0000  0.0714  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.5000  0.0000  0.0000
        )] ;this is Rocky coast values for hyrax etc. appropriate?
    if vt = 11 [ set encounter (list
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
      )]

  ]
  ask patches-coast [
  set mult-undepl (list kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return kcal_return kcal_return kcal_return kcal_return kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return kcal_return kcal_return kcal_return kcal_return) ; looped over two cycles to account for long temporal foresight range
  set mult-repl (list 0 0 0 0 0 0 0 0 0 0 kcal_return kcal_return kcal_return kcal_return kcal_return kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return kcal_return kcal_return kcal_return kcal_return)
  set mult-depl (list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return_min kcal_return kcal_return kcal_return kcal_return kcal_return)
  ]
  set nrspecies 28

  set memoryfood 7

  ;need return rate per species based on animal weight (actually calories to make comparable). Ache had one species rt-rate list
;  let i 0
;  while [i < nrspecies]
;  [
;     set rt-rate replace-item i rt-rate ((60 * item i success-rate * item i weight) / item i pursuit-time )
;     set i i + 1
;  ]

  ;; set up goodcoast?    ;cw is this used?
  ask patches [
    set goodcoast? false
    if (vt = 10 OR vt > 11)                                ; sand (11) is bad coast!
      [set goodcoast? true]
  ]

  ;;*****SET UP CAMPS*****

  create-camps nrcamps
  [
    move-to one-of patches-vt
    set cx pxcor                              ; set cx and cy for agents to find their camp
    set cy pycor
    set shape "house"
    set color red
    set size 5
    set hidden? false
    set hist_kcal_per_day (list 2000 2000 2000 2000 2000 2000 2000)
  ]

  ;;*****SET UP AGENT-GATHERERS*****
  create-agents (nragents * nrcamps) * (1 - hunter-percent)
  [
    set color red
    set hg "g"
    set shape "person"
    set size 5
    set time-forage-budget daily-time-budget
    set dailykcal 0
    set dailykm 0
    set hidden? true
    set campsite min-one-of camps [count agents-here ] move-to campsite
  ]

  ;;*****SET UP AGENT-HUNTERS*****
  create-agents (nragents * nrcamps) * hunter-percent
  [
    set color blue
    set hg "h"
    set shape "person"
    set size 5
    set time-forage-budget daily-time-budget
    set dailykcal 0
    set dailykm 0
    set hidden? true
    set campsite min-one-of camps [count agents-here ] move-to campsite
  ]

  ;for now setup hunters and gatherers, this might not work in future for task-switching. Or alternatively will need to be updated later.
  set hunters agents with [hg = "h"]
  set gathers agents with [hg = "g"]

  ;;*****SET UP OTHER INITIALIZATION PARAMETERS*****
  ;set day 0
  ;set tide "poor"
  set cum_kcal 0
  set time-walk-cell 1 / walk-speed / 10                              ;flip walk-speed to hours / hectare so 2 km/h = .05 hours / hectare
  set camp-mobility daily-time-budget * walk-speed * 10 * 0.75        ;need to set a good value so that agents have time to harvest during the day. this was the purpose of the campless experiments but i'm not sure we came to a good answer.
  ;set newday 1
  ask patches-vt [set current_kcal_return kcal_return_min]
  ask camps [ set overall_avg_kcal 0
    set kcal_total 0
    set kcal_per_day 0
  set coastal_target 0
  ]
  ;set last-OK-tide 0
  ;set days-until-tide 11
  ask patches-vt
  [
    let temp (list)
    let i 1
    ;let r discount_rate
    ;repeat days_of_foresight [set temp lput (1 / i * current_kcal_return) temp set i i + 1]        ; inverse temporal distance weighting [1/1, 1/2, 1/3... 1/days_of_foresight]
    ;repeat days_of_foresight [set temp lput (1 / ((1 + discount_rate) ^ i) * current_kcal_return) temp set i i + 1]        ; weaker net present value rate 1/(1+r)^t, exponential
    repeat days_of_foresight [set temp lput (current_kcal_return / (1 + discount_rate * i)) temp set i i + 1]        ; weaker net present value rate 1/(1+r*t), hyperbolic
    ;repeat days_of_foresight [set temp lput kcal_return temp]
    set temporal_multiplier sum temp                                          ;this value is the temporally weighted return in calories for one hour a day of x days_of_foresight. Essentially a kcal/hr with foresighted days weighed in. Multiply it against daily-time-budget for total kcal harvest over those days, sorta...
    ;if self = patch 50 50 [print temp]

    ;initialise hunting vars
    set enc-dep (list 0.6 0.1 0.8 0.9 0.6 0.4 0.1 0.4 0.9 0.8 0.4 0.1 0.6 0.6 0.1 0.8 0.6 0.6 0.6 0.6 0.9 0.4 0.8 0.8 0.6 0.6 0.6 0.6)
    set relencounter (list 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)

  ]
  ; global hunting var
  set rt-rate (list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
  set hunt-time (list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
  set prey_cal (list 1320000  192000  7500  81000  720000  165000  102000  1044  7500  565500  5400000  252000  22200  12000  193200  2339700  4800  15600  36000  21000  336000  313500  87000  52200  13800  29400  120000  168000)
  set prey_cal_stdev (list 100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100  100)
  set pursuit-time (list 0.0  0.0  0.0  0.0  212.0  0.0  0.0  0.0  0.0  873.6  0.0  153.9  6.3  0.0  0.0  0.0  13.3  0.0  0.0  0.0  6.5  0.0  0.0  0.0  46.4  0.0  72.0  408.0)
  set success-rate (list 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.3  0.0  0.1  0.5  0.0  0.0  0.0  0.2  0.0  0.0  0.0  0.2  0.0  0.0  0.0  0.7  0.0  0.4  0.6)

  set meat_vt (list 0 0 0 0 0 0 0 0 0 0 0 0)
  set time_vt (list 0 0 0 0 0 0 0 0 0 0 0 0)


  set kcal_vt1 0
  set kcal_vt2 0
  set kcal_vt3 0
  set kcal_vt4 0
  set kcal_vt5 0
  set kcal_vt6 0
  set kcal_vt8 0
  set kcal_vt9 0
  set kcal_vt10 0
  set kcal_vt11 0
  set kcal_vt12 0
  set kcal_vt13 0
  set kcal_vt14 0

  ;; display map
  ask patches with [vt = 0] [set pcolor blue]
  run (word "display-" display-mode)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  tick
  tidal-cycle
  update-patches

    run (word "display-" display-mode)

    update-campsites
    ifelse (count patches with [current_kcal_return > 0] != 0) [
      if count gathers > 0 [gather]
      if count hunters > 0 [hunt]
    ][stop]

    ask camps [
       if kcal_per_day / count agents with [campsite = myself] < 100 [set days_without days_without + 1]
       ifelse length hist_kcal_per_day < memoryfood
       [set hist_kcal_per_day lput (kcal_per_day / (count agents with [campsite = myself])) hist_kcal_per_day ]
       [
          let i 0
          while [i < (memoryfood - 1)]
          [
            set hist_kcal_per_day replace-item i hist_kcal_per_day item (i + 1) hist_kcal_per_day
            set i i + 1
          ]
          set hist_kcal_per_day replace-item (memoryfood - 1) hist_kcal_per_day (kcal_per_day / (count agents with [campsite = myself]))
       ]
    ]

    ask camps [
      set kcal_total kcal_total + kcal_per_day
   ;   set overall_avg_kcal (kcal_total / ticks / count agents with [campsite = myself])
      set overall_avg_kcal mean [hist_kcal_per_day] of self
      set total-harvest-time 0 set current_kcal_return 0 set time-until-replenished 365 set pcolor black     ;hack to keep camps moving, though reasonable
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-patches
ask patches-vt
[
  ifelse vt < 10 and time-until-replenished > 0 [set time-until-replenished time-until-replenished - 1][set time-until-replenished days-until-tide]
  if time-until-replenished = 0
  [
    set current_kcal_return kcal_return
    set total-harvest-time pass-harvest-time * 5
  ]
]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to tidal-cycle
  ;; days 1-10 = poor, 11-15 = good, repeat.
  ;0: poor
  ;1: poor
  ;2: poor
  ;3: poor
  ;4: poor
  ;5: poor
  ;6: poor
  ;7: poor
  ;8: poor
  ;9: poor
  ;10: OK
  ;11: OK
  ;12: good       ; enough variation in time of year, weather, swell, that this evens out and doesn't make a difference
  ;13: OK
  ;14: OK
  set tideday remainder ticks 15

  ;; kcal returns for each tidal state
  if tideday = 0 [
    ask patches-coast [if current_kcal_return > kcal_return_min [set current_kcal_return kcal_return_min]]
  ]
  if tideday = 10 [
    ask patches-coast [set current_kcal_return kcal_return]
  ]
  set days-until-tide 10 - tideday ; there are 10 poor days in between tidal cycles

  ask patches-coast
  [
    ;init with undepleted case
    let mult mult-undepl
    if current_kcal_return = 0
      [
        ifelse tideday < 10 [set mult mult-repl] ; case of tide being replenished at next spring
        [set mult mult-depl] ;else tideday >= 10 ; case of tide being replenished to low at next non-spring
      ]
    let i 1
    set temporal_multiplier 0
    while [i <= days_of_foresight]
    [
      set temporal_multiplier temporal_multiplier + (1 / (1 + discount_rate * i)) * item (tideday + i) mult ; hyperbolic
   ;   set temporal_multiplier temporal_multiplier + (1 / (1 + discount_rate ^ i)) * item (tideday + i) mult ; exponential discounting
      set i i + 1
    ]
  ]
; check the calculation of temporal_multiplier later. Now it is the discounted sum of the harvest for the next N (= days_of_foresight days).
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-campsites          ;maybe replace camp-mobility with walkable distance in day? done, calculated in setup from gui param of walk-speed and daily-time-budget

  ask camps [
    if overall_avg_kcal < camp-move-threshold [     ;not sure I like the location of this, but camps have to be below a kcal harvest threshold to both moving.
    set kcal_per_day 0
    ifelse spatial-foresight = true [
      spatial-foresight-movement
    ]
    [; else spatial-foresight false = random camp mobility
      let found 0
      while [found = 0] [
        let p patch-at-heading-and-distance random 360 camp-mobility
        if p != nobody AND [vt] of p > 0
        [move-to p]
      ]; close while
    ]; close spatial-foresight else
    set hist_kcal_per_day []
  ]]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to spatial-foresight-movement          ;called by camps in update-campsites
  let best_pot_camp patch 0 0
  ifelse global-knowledge? [
    ;set best_pot_camp pick-patch-global      ;deprecated
    set best_pot_camp pick-patch-global-tidal-foresight
  ][
    ;set best_pot_camp pick-patch-local
    set best_pot_camp pick-patch-local-tidal-foresight          ;need to update for hunting.
    ;test4
  ]
  ifelse [current_kcal_return] of best_pot_camp = 0 OR count other camps-on best_pot_camp > 0
    [
      move-to max-one-of patches-at-radius (walk-speed * 10) [current_kcal_return] ;move to a cell one hour walk away
    ]
    [ ;else target good so move to/towards
      ifelse distance best_pot_camp <= camp-mobility       ;within movement range?
      [
        move-to best_pot_camp
      ]
      [ ;else move towards location
        face best_pot_camp
        ifelse [vt] of patch-ahead camp-mobility > 0
        [
          move-to patch-ahead camp-mobility
        ]
        [ ;else there's ocean in the way
          ;move-to one-of neighbors with [vt > 0]            ; these movements too small
          move-to max-one-of patches-at-radius camp-mobility [current_kcal_return]          ; maybe an odd fix, but it works and is uncommon anyway. places camps along an camp-mobility distant arc
        ]
      ]
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to gather
  ;;*****INITIALIZE A NEW DAY*****
  ask gathers [
    set dailykcal 0
    set dailykm 0
    set time-forage-budget daily-time-budget
    set done 0
   ]

  ;; *****ACTUAL FORAGING (INCLUDING KEEPING TRACK OF TIME AND DISTANCE TO CAMP)*****
  let allgathersdone 0
  while [allgathersdone = 0] ;all agent movement happens within a tick, works but hard to eval since you can't see inside the loop very well
    [
      ask gathers with [done = 0][
        ;set timecamp distance campsite * [pass-harvest-time] of patch-here         ; expected time (in minutes) for an agent to walk back to the camp harvesting along the way
        set timecamp distance campsite * time-walk-cell                             ; expected time (in minutes) for an agent to walk straight back to the camp without harvesting
        ifelse time-forage-budget > timecamp                                       ; true if time budget is less than the time it takes to cross a cell (aka time to go home)
          [ ; time left for foraging
            ; so agent moves to forage
            ; in this version, foragers move on if the current_kcal_return of the patch they are on drops below the average for the patches they could potentially move to
            ; whether they move to the best patch in this radius is determined by the switch "forager-movement"; code is under "move" process
            ;if (current_kcal_return = 0 OR current_kcal_return < mean [current_kcal_return] of patches-vt in-radius vision) [move] ;"neighbors better" MVT
            move-gather     ;jan16 foragers pick a distant cell but then harvest towards it so never reach. issue bc timecamp is based on harvesting on the way home.
          ]
          [ ;else no extra foraging time left, "forage on the way home"
            face campsite
            let found 0
            ifelse [vt] of patch-ahead 1 > 0
            [
              move-to patch-ahead 1 set found 1
            ]
            [
              while [found = 0]
              [
                if patch-ahead 1 != nobody [
                  if [vt] of patch-ahead 1 > 0 [move-to patch-ahead 1 set found 1]
                ]
                if found = 0 [rt random 45 lt random 45]
              ]
            ] ;close else patch-ahead
            ;update-numbers
            set time-forage-budget time-forage-budget - time-walk-cell
            set dailykm dailykm + .1
          ] ; close else time left
        ;set timecamp distance campsite * [pass-harvest-time] of patch-here
        set timecamp distance campsite * time-walk-cell
        ;if (distance campsite < 1.5 AND time-forage-budget < [pass-harvest-time] of patch-here) OR dailykcal > max_kcal_to_harvest [      ;next to or at campsite and foraging time has run out OR have enough kcal
        if (distance campsite < 1.5 AND time-forage-budget < time-walk-cell) OR dailykcal > max_kcal_to_harvest OR time-forage-budget < 0 [      ;next to or at campsite and foraging time has run out OR have enough kcal
          let d distance campsite
          move-to campsite ;teleports agents home if they've harvested enough
          set dailykm dailykm + d
          set done 1 ;   show time-forage-budget ; they're consistently over-shooting their foraging budget since they check time against current patch, then move to a patch w/ different harvest time
        ]

      ] ;close ask gathers

      if sum [done] of gathers = count gathers [
        set allgathersdone 1
        ask gathers with [dailykcal < 100]
        [
          set days_without days_without + 1
        ]
        ask camps [
          set kcal_per_day sum [dailykcal] of gathers with [campsite = myself]
        ]
      ]
    ]  ;close while
end

to hunt
    ;;*****INITIALIZE A NEW DAY*****
  ask hunters [
    set dailykcal 0
    set dailykm 0
    set time-forage-budget daily-time-budget
    set done 0
   ]
  ;; *****ACTUAL HUNTING (INCLUDING KEEPING TRACK OF TIME AND DISTANCE TO CAMP)*****
  let allhuntersdone 0
  while [allhuntersdone = 0] ;all agent movement happens within a tick, works but hard to eval since you can't see inside the loop very well, subtick?
    [
      ask hunters with [done = 0][
        set timecamp distance campsite * time-walk-cell                             ; expected time (in minutes) for an agent to walk straight back to the camp
        ifelse time-forage-budget > timecamp                                       ; true if time budget is less than the time it takes to cross a cell (aka time to go home)
          [ ; time left for foraging
            ; so agent moves to search
            move-hunt
            set time-forage-budget time-forage-budget - time-walk-cell
            encounterprocedure
          ]
          [ ;else no time left, head home
            face campsite
            let found 0
            ifelse [vt] of patch-ahead 1 > 0
            [
              move-to patch-ahead 1 set found 1
            ][
              while [found = 0]
              [
                if patch-ahead 1 != nobody [
                  if [vt] of patch-ahead 1 > 0 [move-to patch-ahead 1 set found 1]
                ]
                if found = 0 [rt random 45 lt random 45]
              ]
              set time-forage-budget time-forage-budget - time-walk-cell
              encounterprocedure
            ] ;close else patch-ahead
            set dailykm dailykm + .1
          ] ; close else time left
        ;set timecamp distance campsite * [pass-harvest-time] of patch-here
        set timecamp distance campsite * time-walk-cell
        ;if (distance campsite < 1.5 AND time-forage-budget < [pass-harvest-time] of patch-here) OR dailykcal > max_kcal_to_harvest [      ;next to or at campsite and foraging time has run out OR have enough kcal
        if (distance campsite < 1.5 AND time-forage-budget < time-walk-cell) OR time-forage-budget < 0 [      ;next to or at campsite and foraging time has run out OR time has run out
          let d distance campsite
          move-to campsite ;teleports agents home if they've harvested enough
          set dailykm dailykm + d
          set done 1 ;   show time-forage-budget ; they're consistently over-shooting their foraging budget since they check time against current patch, then move to a patch w/ different harvest time
        ]

      ] ;close ask hunters
      if sum [done] of hunters = count hunters [
        set allhuntersdone 1
        ask hunters with [dailykcal < 100]
        [
          set days_without days_without + 1
        ]
        ask camps [ ;not sure this is right with the split. maybe put back into go.
          set kcal_per_day kcal_per_day + sum [dailykcal] of hunters with [campsite = myself]
        ]
      ]
    ]  ;close while
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-gather
  ifelse forager-movement = "random" [
    let p one-of neighbors with [current_kcal_return > 0]
    ifelse p != nobody [move-to p][move-to one-of neighbors with [vt > 0]]
    set time-forage-budget time-forage-budget - time-walk-cell
    update-gather-numbers
  ]
  [  ; find best patch within vision radius, then move to that patch
    let best-patch self
    ifelse days-until-tide = 0 [
      set best-patch pick-patch-local-tidal
    ][
      set best-patch max-one-of patches in-radius vision-forager [current_kcal_return * ([time-forage-budget] of myself - (time-walk-cell * distance myself))]
    ]
    ifelse best-patch != patch-here and [current_kcal_return] of best-patch > 0
    [
      ifelse distance best-patch < 1.5                       ;if neighbouring cell move there then harvest, else move towards but don't harvest on the way
      [
        move-to best-patch
        set time-forage-budget time-forage-budget - time-walk-cell
        update-gather-numbers
      ][ ;else farther so walk towards
        face best-patch
        ifelse is-patch? patch-ahead 1 and [vt > 0] of patch-ahead 1 [
          move-to patch-ahead 1
          set time-forage-budget time-forage-budget - time-walk-cell
          set dailykm dailykm + .1
        ][ ;else     if you can't move to or towards the best, move anywhere!
          move-to one-of neighbors with [vt > 0]
          update-gather-numbers
        ]
      ] ;close if distance
    ]
    [
      let p one-of neighbors with [current_kcal_return > 0]
    ifelse p != nobody [move-to p][move-to one-of neighbors with [vt > 0]]
    set time-forage-budget time-forage-budget - time-walk-cell
    update-gather-numbers
      ;else best-patch is here or best-patch is empty (in dead zone)
   ;   ifelse current_kcal_return = 0 [                                                     ; was random walking if unable to find a quality patch, now they walk towards nearest non-zero patch
   ;     let p min-one-of patches with [current_kcal_return > 0] [distance myself]
   ;     let dp distance p
   ;     if [vt] of p > 0 [
   ;       move-to p
   ;       set time-forage-budget time-forage-budget - (time-walk-cell * dp)
   ;       set dailykm dailykm + (.1 * dp)
   ;       ]
   ;   ] ;have them walk towards nearest non-zero return
   ;   [ ;else
   ;    ; update-gather-numbers
   ;   ]
    ]
  ]
end

to move-hunt
  ;needs update-numbers, not sure it needs all the flocking, but does need some kind of spread and walk
  ;face campsite
  ;let p one-of patches-vt in-cone 1.5 180
  ;move-to p
  let p one-of patches in-radius 1.5 with [vt > 0]
;  let dp distance p
  move-to p
;  set time-forage-budget time-forage-budget - (time-walk-cell * dp)
;  set dailykm dailykm + (.1 * dp)
end



to-report pick-patch-global                  ;currently assuming that every camp has full knowledge of other camps.
    report max-one-of patches-vt [current_kcal_return * (daily-time-budget - (time-walk-cell * distance myself))]                   ;this doesn't work because camp-mobility is restricted, also camps set out for tide even if not going to make it before end of spring tide
end

to-report pick-patch-global-tidal-foresight          ;clone of the local version but for the full land patch set instead of just in-radius
  ifelse is-camp? self
  [
     let p max-one-of patches-vt [
      ifelse-value goodcoast?
      [
        ;next line is for coastal cells, it adds calories for 2 h of coastal foraging and rest of day of terrestrial foraging on the nearest terrestrial cell, then subtracts out calories lost from traveling instead of foraging in place as usual.
        (ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * 2) + ([ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0]] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * (daily-time-budget - 2)) - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)

      ]
      [
        ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
      ]
    ]
    ask p [set pcolor cyan]
    report p
  ]
  [
    print "Don't use for foragers"
    report one-of patches
  ]
end


to-report pick-patch-local ;[anticipated-return]
  ;report min-one-of patches in-radius vision with-max [current_kcal_return][distance myself]
  ifelse is-camp? self ;camps?   ;allows same function to be used by camps and foragers
  [
    report max-one-of patches in-radius vision-camp [current_kcal_return * (daily-time-budget - (time-walk-cell * distance myself))]
  ]
  [
    report max-one-of patches in-radius vision-forager [(current_kcal_return * ([time-forage-budget] of myself - (time-walk-cell * distance myself)))]
  ]
end

to-report pick-patch-local-tidal
  ; calculates the best patch to gather when the tide is right for shellfish gathering
    let coastpatch min-one-of patches-coast [distance myself]
    ifelse (time-forage-budget > daily-time-budget - 2) and ((time-forage-budget < (time-walk-cell * (distance coastpatch))))          ;low tide coastal or terrestrial, after that terrestrial only. problem since 2 tides a day, could have used torches for new moon, even without on full. Change to 4 hours and ignore that they're not sequential?
    [
      let p max-one-of (patch-set patches in-radius vision-forager patches-coast) [current_kcal_return * (2 - (daily-time-budget - [time-forage-budget] of myself) - (time-walk-cell * distance myself))]
      report p
    ]
    [ ;else rest of day on terrestrial
      let p max-one-of patches in-radius vision-forager [ifelse-value (goodcoast? AND current_kcal_return > 0) [kcal_return_min][current_kcal_return] * ([time-forage-budget] of myself - (time-walk-cell * distance myself))]
      report p
    ]
end

to-report pick-patch-local-tidal-foresight
  ; if coast only 2h (but 3h more terrestrial if available), if terrestrial 6h
  ; ok so 2h of coastal target, plus rest of day with nearest terrestrial resource above zero kcal_return. Can't take current_ bc it's distant
  ifelse is-camp? self
  [
    ; need to weigh this against coastal hours per day... used 4h for now, inconsistent with other versions though, also underestimates the terrestrial foraging returns for the remainder of the day...
    ;report max-one-of (patch-set patches in-radius vision-camp patches-coast) [current_kcal_return * ifelse-value goodcoast? [temporal_multiplier_coast * ( 4 / daily-time-budget ) ][temporal_multiplier_terre] * (daily-time-budget * days_of_foresight - (time-walk-cell * distance myself))]
    ;;; this isn't right, should be return rate * time, where time = daily-time-budget * mult - distance / camp-mobility?
    ;;; return_rate * days * daily-time-budget * days_of_foresight / distance / camp-mobility that's days of travel to target subtracted from days...


    ; flawed as camps are not taking forager harvests along the way into account. Works when travelling through depleted zones, but not through harvestable habitats. Taxing travel too heavily.
    ; They need to know if the intermediate territory is depleted or not
    ; multiply the tax by an overall expected proportion of depletion? not great, sum [current_kcal_return] of patches-vt / sum [kcal_return] of patches-vt
    ; temp fix is to count only 1/3 of the tax (arbitrary)

    ;Jan16, need to put the coastal forgaging time limits back in
    ;one way to do this is to pick a the top terrestial patch and the top coastal patch then take best of. have to calc twice but simplifies the math of time estimation.
    ;even so, won't be optimizing time spent in terms of best coastal cell within range of good terrestrial resources for rest of day, though should hit the harvest limit anyway if coast... sigh.
;    let p max-one-of (patch-set patches in-radius vision-camp patches-coast) [
;      ;ifelse-value (current_kcal_return > 0 or goodcoast?) [temporal_multiplier] [0] * daily-time-budget - (0.33 * (distance myself / camp-mobility * daily-time-budget * current_kcal_return))      ;this should be the days of travel * work hours per day * return rate = kcal lost from travel
;      ifelse-value (current_kcal_return > 0 or goodcoast?) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
;      ;ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * daily-time-budget - (current_kcal_return * time-walk-cell * distance myself)   ;this is more of a forager version
;    ]
    ;ask p [type "temporal_multiplier: " type temporal_multiplier type " daily-time-budget: " type daily-time-budget type " = " print temporal_multiplier * daily-time-budget]
    ;ask p [type "distance: " type distance myself type " camp-mobility: " type camp-mobility type " = " print distance myself / camp-mobility ]

    ;jan16 ok let's try a split and compare version
;    let pt max-one-of patches in-radius vision-camp [ ;best terrestrial patch for full day's foraging first
;       ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
;    ]
;    let pc max-one-of patches-coast [ ;best coastal patch for 2h only? add in rest of day terrestrial or just run all day in terms of camp calc bc they're likely to be beside other coastal cells. Foragers factor in timing into actual harvesting.
;       (ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * 2) + ([temporal_multiplier] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * (daily-time-budget - 2)) - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
;    ]
     ;no way to save the "value" from max-one-of so need to run the math again regardless. Need a bigger expression with ifelse-value switch to fix
     ; Actually works!
    let p max-one-of (patch-set patches in-radius vision-camp patches-coast) [
      ifelse-value goodcoast?
      [
        ;next line is for coastal cells, it adds calories for 2 h of coastal foraging and rest of day of terrestrial foraging on the nearest terrestrial cell, then subtracts out calories lost from traveling instead of foraging in place as usual.
        ;maybe remove the current_kcal_return > 0 bit since distant coastal cells shouldn't be eval-able for current_ state. done replaced with just temporal_multiplier
        ; robs peter to pay paul. if I take out current then coastal cells within visual range are over-emphasised. gonna let this one go
        (ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * 2) + ([ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0]] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * (daily-time-budget - 2)) - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
        ;(temporal_multiplier * 2) + ([ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0]] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * (daily-time-budget - 2)) - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
      ]
      [
        ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
      ]
    ]

    ask p [set pcolor cyan]
    report p

  ]
  [ ; this section is flawed as current_ is multiplied, rather than actual forecasting, patches need high and low kcal (like current_kcal_return_hightide)
;    ifelse time-forage-budget > daily-time-budget - 2 and days-until-tide = 0         ;low tide coastal or terrestrial, after that terrestrial only. problem since 2 tides a day, could have used torches for new moon, even without on full. Change to 4 hours and ignore that they're not sequential?
;    [ ;can max-one-of be run differently if coast vs if terrestrial? maybe not but could add the multiplier as a patch variable, requires updating coastal var each tick in tidal-cycle....
;      ;report max-one-of (patch-set patches in-radius vision-forager patches-coast) [current_kcal_return * ifelse-value goodcoast? [temporal_multiplier_coast][temporal_multiplier_terre] * ([time-forage-budget] of myself - (time-walk-cell * distance myself))]
;    ][
;      report max-one-of patches in-radius vision-forager [ifelse-value goodcoast? [105][current_kcal_return] * ([time-forage-budget] of myself - (time-walk-cell * distance myself))]
;    ]
    print "Don't use for foragers"
    report one-of patches
  ]
end

to-report pick-patch-hunt    ;called by camps
  ;what's the logic here? how do I compare gather returns vs hunting? or do I just pick hunting targets and let gather follow? contrary to spirit of shellfish issue
  ;what does Ache code do? from ache v1.1b:
  ; set nearest min-one-of patches with [vt = 5 and item whichcamp timelast < (day - recoverytime)][distance myself]
  ; then if nobody choose vt = 7, then moves to if between 10 and 30 cells otherwise moves randomly 20
  ; whichcamp list is held by patches and is a camplist to see if they've been in-radius 10 inside of the recoverytime
  ; so targeted switch means they choose a new cell of a preferred return rate (not current_kcal but habitat based) and move to closest of at least 10 but less than 30 cells (1-3 km)
  ; it also has adaptive switch where they stay if the previous day was good by X threshold.
  ; success of 4 strategies varied depending on clumpiness of the landscape habitats.
  ; approach will be to experiment with decision making strategies, ideally this will help evaluate strategies and be ported to broader version later
  ; ie. one version purely based on hunting returns, one on kcal, one based on plant, lowest risk, etc.

  ;dec2016
  ; assume global knowledge, move how far?, how to rank vts based on returns? Since encounter rates/returns are uncertain, no need for patch to patch comparison, just rank vts
  ; how does days-of-foresight work here? it should as vts expected returns should be weighed against lost kcal from travel time, days-of-foresight makes it more worth it to move
  ; pick patch is one cell, maybe consider a radius around to be also high, this is comp intensive, but Marco suggested a random sampling around. Messy...

end

to-report pick-patch-local-tidal-foresight_image
  let p max-one-of (patch-set patches in-radius vision-camp patches-coast) [
    ifelse-value goodcoast?
    [
      (ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * 2) +
      ([ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0]] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * (daily-time-budget - 2)) -
      (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
    ]
    [
      ifelse-value (current_kcal_return > 0) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return)
    ]
  ]
  ask p [set pcolor cyan]
  report p
end

to-report pick-patch-local-tidal-land     ;needed to modify so that foragers think not just about that one moment but the day's worth. Or should I?
  ; Problem is that foragers run for coast but don't make it. They need their own daily foresight? The below should have been the main prob. But foragers still not counting off-coast 4h like camps do.
  ;x another issue is that the time of day switch (for low tide) doesn't do max of vs rest of day so it's like double counter, one for morning, then one for afternoon.
  ;x need to keep both and compare? will take longer?
  ;x if coast only 2h (but 4h more terrestrial if available), if terrestrial 6h
;  ifelse is-camp? self    ;supposed to be used for foragers
;  [
;    print "Don't use for camps"
;    report one-of patches
;  ]
;  [
; ok so time to mod like the camp pick for adjacent terrestrial
; this all works like it should (I think) but it has gotten slow 2.x ms /call
  let p max-one-of (patch-set patches in-radius vision-forager with [vt > 0] patches-coast)
    [
      max (list
        ;marine: if (daily-left) + travel < tide, tide - (daily-left) - travel, 0
        ((current_kcal_return * (ifelse-value ((daily-time-budget - [time-forage-budget] of myself) + (time-walk-cell * distance myself) < 2) [2 - (daily-time-budget - [time-forage-budget] of myself) - (time-walk-cell * distance myself)][0])) +
        ;terrestrial: if (daily-left) + travel < tide, daily-tide, left-travel
          ([current_kcal_return] of one-of patches in-radius 1.5 with [vt > 0 AND vt < 10] * ;flags if local cells empty, switch to mini max-one-of?
            ifelse-value ((daily-time-budget - [time-forage-budget] of myself) + (time-walk-cell * distance myself) < 2) [daily-time-budget - 2] [[time-forage-budget] of myself - (time-walk-cell * distance myself)]
            ))
        (ifelse-value (goodcoast? AND current_kcal_return > 0) [kcal_return_min] [current_kcal_return] * ([time-forage-budget] of myself - (time-walk-cell * distance myself)))
      )
    ]
  report p
  ;  ]
end


to-report pick-patch-local-tidal-land-old     ;needed to modify so that foragers think not just about that one moment but the day's worth. Or should I?
  ; Problem is that foragers run for coast but don't make it. They need their own daily foresight? The below should have been the main prob. But foragers still not counting off-coast 4h like camps do.
  ;x another issue is that the time of day switch (for low tide) doesn't do max of vs rest of day so it's like double counter, one for morning, then one for afternoon.
  ;x need to keep both and compare? will take longer?
  ; if coast only 2h (but 3h more terrestrial if available), if terrestrial 6h
;  ifelse is-camp? self    ;supposed to be used for foragers
;  [
;    print "Don't use for camps"
;    report one-of patches
;  ]
;  [
  let p max-one-of (patch-set patches in-radius vision-forager patches-coast)
    [
      max (list
        (current_kcal_return * (2 - (daily-time-budget - [time-forage-budget] of myself) - (time-walk-cell * distance myself)))
        (ifelse-value (goodcoast? AND current_kcal_return > 0) [kcal_return_min] [current_kcal_return] * ([time-forage-budget] of myself - (time-walk-cell * distance myself)))
      )
    ]
  report p
  ;  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to encounterprocedure ; check whether a species is encountered
  if [vt] of patch-here > 0 [
    let species []
    let ii 0
    while [ii < nrspecies]  ; define list of species
    [
      set species lput ii species
      set ii ii + 1
    ]
    set counted 0
    while [counted < nrspecies] ; we go randomly through the species list and stop if we encounter an animal of a species
    [
      let draw one-of species
      updatespecies draw
      set species remove draw species
      set counted counted + 1
    ]
  ]
end

; for each type of encounter we add the average time for each pursuit and the probability of a successful hunt (including the options of cooperative hunting)
to updatespecies [draw] ; for a given species

  if ((draw != 8) or (draw = 8 and ticks > 242)) [ ;cw day is based on seasonality, need to work in how I'll do that here. change to tick for now
    if random-float 1 < ((item draw encounter * item draw relencounter) * ( (item draw enc-dep) ^ ([crowding] of patch-here - 1))) [     ;this is the prob of encounter part, input encounter unit is in N encounters / 100 m
      let exp-rt-rate item draw rt-rate
      let cnc 0 ; = 1 if a cooperative opportunity is ignored
;cw coop hunting part 1 here (deleted)
      let campself campsite
      ifelse exp-rt-rate >= avgpastrr [;* PN [ ; PN is pursuit or not. if PN is 0, agents will always pursuit, cw mod to always pursue
        let groupsize 0
        let hunterpx xcor
        let hunterpy ycor
        set campself campsite
        ask agents [set potmeat 0]
        set counted 100
        ;cw coop hunting part 2 here (deleted)
        set pursuit item draw pursuit-time
        set hunt-time replace-item draw hunt-time (item draw hunt-time + pursuit)
        ;set tot_ht tot_ht + item draw pursuit-time
        ;set time-pursuit time-pursuit + item draw pursuit-time
        set time-forage-budget time-forage-budget - pursuit   ;cw maybe?
        updatereturnrate (item draw pursuit-time)
        if random-float 1 < item draw success-rate [
          ;set nrcaught replace-item draw nrcaught ((item draw nrcaught) + 1)
          ;ask patch-here [set caught replace-item draw caught (item draw caught + 1)]
          updatemeat item draw prey_cal ;weight
          set potmeat var_kcal_return item draw prey_cal item draw prey_cal_stdev
                                         ;deplete draw 1
        ]
;      ] ;close coophunting
        ask hunters [set dailykcal dailykcal + potmeat]
      ][  ;not pursue
;        set lost-opp replace-item draw lost-opp (item draw lost-opp + 1)
      ]
    ]
  ]
end

to updatereturnrate [tim]
  if [vt] of patch-here = 1 [set time_vt replace-item 0 time_vt (item 0 time_vt + tim)]
  if [vt] of patch-here = 2 [set time_vt replace-item 1 time_vt (item 1 time_vt + tim)]
  if [vt] of patch-here = 3 [set time_vt replace-item 2 time_vt (item 2 time_vt + tim)]
  if [vt] of patch-here = 4 [set time_vt replace-item 3 time_vt (item 3 time_vt + tim)]
  if [vt] of patch-here = 5 [set time_vt replace-item 4 time_vt (item 4 time_vt + tim)]
  if [vt] of patch-here = 6 [set time_vt replace-item 5 time_vt (item 5 time_vt + tim)]
  if [vt] of patch-here = 8 [set time_vt replace-item 6 time_vt (item 6 time_vt + tim)]
  if [vt] of patch-here = 9 [set time_vt replace-item 7 time_vt (item 7 time_vt + tim)]
  if [vt] of patch-here = 10 [set time_vt replace-item 8 time_vt (item 8 time_vt + tim)]
  if [vt] of patch-here = 12 [set time_vt replace-item 9 time_vt (item 9 time_vt + tim)]
  if [vt] of patch-here = 13 [set time_vt replace-item 10 time_vt (item 10 time_vt + tim)]
  if [vt] of patch-here = 14 [set time_vt replace-item 11 time_vt (item 11 time_vt + tim)]

end

to updatemeat [kcal]
  if [vt] of patch-here = 1 [set meat_vt replace-item 0 meat_vt (item 0 meat_vt + kcal)]
  if [vt] of patch-here = 2 [set meat_vt replace-item 1 meat_vt (item 1 meat_vt + kcal)]
  if [vt] of patch-here = 3 [set meat_vt replace-item 2 meat_vt (item 2 meat_vt + kcal)]
  if [vt] of patch-here = 4 [set meat_vt replace-item 3 meat_vt (item 3 meat_vt + kcal)]
  if [vt] of patch-here = 5 [set meat_vt replace-item 4 meat_vt (item 4 meat_vt + kcal)]
  if [vt] of patch-here = 6 [set meat_vt replace-item 5 meat_vt (item 5 meat_vt + kcal)]
  if [vt] of patch-here = 8 [set meat_vt replace-item 6 meat_vt (item 6 meat_vt + kcal)]
  if [vt] of patch-here = 9 [set meat_vt replace-item 7 meat_vt (item 7 meat_vt + kcal)]
  if [vt] of patch-here = 10 [set meat_vt replace-item 8 meat_vt (item 8 meat_vt + kcal)]
  if [vt] of patch-here = 12 [set meat_vt replace-item 9 meat_vt (item 9 meat_vt + kcal)]
  if [vt] of patch-here = 13 [set meat_vt replace-item 10 meat_vt (item 10 meat_vt + kcal)]
  if [vt] of patch-here = 14 [set meat_vt replace-item 11 meat_vt (item 11 meat_vt + kcal)]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report kcal-avg
    report mean [overall_avg_kcal] of camps
end

to display-vt
  ask patches-vt [
    ;if vt = 0  [set pcolor 105]     ; no data; blue to simulate water
    if vt = 1  [set pcolor 88]      ; Freshwater wetlands
    if vt = 2  [set pcolor 86]      ; Alluvial Vegetation
    if vt = 3  [set pcolor 116]     ; Strandveld
    if vt = 4  [set pcolor 16]      ; Saline Vegetation
    if vt = 5  [set pcolor 46]      ; Renosterveld
    if vt = 6  [set pcolor 56]      ; Sand Fynbos
    if vt = 8  [set pcolor 76]      ; Thicket
    if vt = 9  [set pcolor 126]     ; Limestone Fynbos
    if vt = 10 [set pcolor 53]      ; Aeolianite (Coastal)
    if vt = 11 [set pcolor 26]      ; Sandy Beach (Coastal)
    if vt = 12 [set pcolor 34]      ; TMS Boulders (Coastal)
    if vt = 13 [set pcolor 35]      ; TMS Eroded Rocky Headlands (Coastal)
    if vt = 14 [set pcolor 36]      ; TMS Wave Cut Platforms (Coastal)
  ]
end

to display-kcal             ;this is logged ; could be turned to single patch, then ask patches in go code... avoid dupe in update-patches
  let max-cal 1500 ;max [kcal_return] of patches
  ;ifelse ticks > 0 [ask patches-vt [set pcolor scale-color green log (current_kcal_return + 1) 10 0 log max-cal 10]][ask patches-vt [set pcolor scale-color green log (current_kcal_return + 1) 10 0 log max-cal 10]]
  ;ifelse ticks > 0 [ask patches-vt [set pcolor scale-color green current_kcal_return 0 max-cal]][ask patches-vt [set pcolor scale-color green current_kcal_return 0 max-cal ]]
  ask patches-vt [
    ifelse current_kcal_return > 0 [set pcolor scale-color green current_kcal_return 0 max-cal][set pcolor 2]
  ]
end

to display-hybrid     ; replace with a vt or black version
    ask patches-vt [
    ;if vt = 0  [set pcolor 105]     ; no data; blue to simulate water
    if vt = 1  [set pcolor 88 - (1 - current_kcal_return / kcal_return)]      ; Freshwater wetlands
    if vt = 2  [set pcolor 86 - (1 - current_kcal_return / kcal_return)]      ; Alluvial Vegetation
    if vt = 3  [set pcolor 116 - (1 - current_kcal_return / kcal_return)]     ; Strandveld
    if vt = 4  [set pcolor 16 - (1 - current_kcal_return / kcal_return)]      ; Saline Vegetation
    if vt = 5  [set pcolor 46 - (1 - current_kcal_return / kcal_return)]      ; Renosterveld
    if vt = 6  [set pcolor 56 - (1 - current_kcal_return / kcal_return)]      ; Sand Fynbos
    if vt = 8  [set pcolor 76 - (1 - current_kcal_return / kcal_return)]      ; Thicket
    if vt = 9  [set pcolor 126 - (1 - current_kcal_return / kcal_return)]     ; Limestone Fynbos
    if vt = 10 [set pcolor 53 - (1 - current_kcal_return / kcal_return)]      ; Aeolianite (Coastal)
    if vt = 11 [set pcolor 26 - (1 - current_kcal_return / kcal_return)]      ; Sandy Beach (Coastal)
    if vt = 12 [set pcolor 34 - (1 - current_kcal_return / kcal_return)]      ; TMS Boulders (Coastal)
    if vt = 13 [set pcolor 35 - (1 - current_kcal_return / kcal_return)]      ; TMS Eroded Rocky Headlands (Coastal)
    if vt = 14 [set pcolor 36 - (1 - current_kcal_return / kcal_return)]      ; TMS Wave Cut Platforms (Coastal)
  ]
end

to-report patches-at-radius [rad]
    ;ask camps [ask patches-at-radius rad [blah]]
    report (patch-set patches-vt with [distance myself > rad - 1 AND distance myself <= rad])
end

to display-none
  if ticks <= 1 [if display-mode = "vt" [display-vt]]
end

to display-time-replenished
  ask patches-vt
  [
    if ticks > 0 [set pcolor scale-color red time-until-replenished 365 0]
  ]
end

to display-times-harvested
  let max-harvest max [times-harvested] of patches
  ask patches-vt
  [
    if ticks > 0 [set pcolor scale-color red times-harvested 0 (max-harvest + 1)]
  ]
end

to update-gather-numbers          ; this is the accounting of harvesting agents and depleting patches
  set dailykcal dailykcal + (pass-harvest-time * current_kcal_return)
  ;set dailykcal dailykcal + (pass-harvest-time * (var_kcal_return current_kcal_return stdev_kcal_return))       ;enable to turn on variable mean/stdev returns
  set dailykm dailykm + .1       ;jan16 with the walk to target just implemented, agents aren't counting km when just traveling
  ifelse total-harvest-time > 0
  [
    set time-forage-budget time-forage-budget - pass-harvest-time
    ask patch-here [
      set total-harvest-time total-harvest-time - pass-harvest-time
      set times-harvested times-harvested + 1            ;this needs to be fixed to properly account neap tide harvests in behaviourspace
      if total-harvest-time <= 0 [set total-harvest-time 0 set current_kcal_return 0 set time-until-replenished 365 set pcolor black]

    ]
  ][ ;else already all harvested
    set time-forage-budget time-forage-budget - time-walk-cell
  ]
end

to-report var_kcal_return [kcal_mean kcal_stdev]         ;instead of a constant rate of return, this will pull a number from mean and stdev
  let c random-normal kcal_mean kcal_stdev
  ifelse c > 0 [report c][report 0]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to test1
   ask pick-patch-global [set pcolor red]
end

to test2
  ask pick-patch-local [set pcolor yellow]
end

to test3
  ask pick-patch-local-tidal-land [set pcolor orange]
end

to test4
  ask pick-patch-local-tidal-foresight [
    set pcolor cyan
    ;ifelse-value (current_kcal_return > 0 or goodcoast?) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return * temporal_multiplier_general)
    print (word "kcal term: " (ifelse-value (current_kcal_return > 0 or goodcoast?) [temporal_multiplier] [0] * daily-time-budget) " distance term: " (distance myself / camp-mobility * daily-time-budget * current_kcal_return ) " result: " (ifelse-value (current_kcal_return > 0 or goodcoast?) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return )))
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
218
7
1008
578
-1
-1
0.65
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
779
0
539
1
1
1
ticks
30.0

BUTTON
3
10
126
43
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
3
43
126
76
go
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

SLIDER
4
147
127
180
nragents
nragents
1
50
30
1
1
NIL
HORIZONTAL

BUTTON
3
76
126
109
tick
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
4
427
127
472
forager-movement
forager-movement
"random" "local-patch-choice"
1

MONITOR
1025
12
1164
57
mean-daily-kcal-per-agent
kcal-avg
0
1
11

PLOT
1025
460
1544
701
time-foraged-by-habitat
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Alluvial" 1.0 1 -8990512 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 2] / sum [time-foraged-here] of patches]]"
"Strandveld" 1.0 1 -6917194 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 3] / sum [time-foraged-here] of patches]]"
"Saline" 1.0 1 -2139308 true "" ";if plots? [if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 4] / sum [time-foraged-here] of patches]]]"
"Renosterveld" 1.0 1 -987046 true "" ";if plots? [if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 5] / sum [time-foraged-here] of patches]]]"
"Sand Fynbos" 1.0 1 -8732573 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 6] / sum [time-foraged-here] of patches]]"
"Thicket" 1.0 1 -11881837 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 8] / sum [time-foraged-here] of patches]]"
"Limestone Fynbos" 1.0 1 -4699768 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 9] / sum [time-foraged-here] of patches]]"
"Aeolianite" 1.0 1 -13210332 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 10] / sum [time-foraged-here] of patches]]"
"Sandy Beach" 1.0 1 -817084 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 11] / sum [time-foraged-here] of patches]]"
"TMS Boulders" 1.0 1 -8431303 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 12] / sum [time-foraged-here] of patches]]"
"TMS Eroded Rocky Headlands" 1.0 1 -6459832 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 13] / sum [time-foraged-here] of patches]]"
"TMS Wave Cut Platforms" 1.0 1 -5207188 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 14] / sum [time-foraged-here] of patches]]"
"Freshwater wetlands" 1.0 0 -4528153 true "" ";if plots? [if ticks > 0 [plot sum [time-foraged-here] of patches with [vt = 1] / sum [time-foraged-here] of patches]]"

SWITCH
4
517
127
550
spatial-foresight
spatial-foresight
0
1
-1000

PLOT
1173
12
1373
162
daily kcal
NIL
NIL
0.0
10.0
0.0
2000.0
true
false
"" ""
PENS
"dailykcal" 1.0 0 -7500403 true "" "if plots? [if ticks > 0 [plotxy ticks mean [dailykcal] of agents]]"
"mean_daily_kcal" 1.0 0 -14439633 true "" ";if plots? [ask camps [plotxy ticks overall_avg_kcal]]\nif plots? and ticks > 0 [plotxy ticks kcal-avg]"

SLIDER
2
241
124
274
vision-camp
vision-camp
0
50
50
5
1
NIL
HORIZONTAL

SLIDER
2
274
125
307
vision-forager
vision-forager
0
75
10
5
1
NIL
HORIZONTAL

MONITOR
1070
111
1120
156
NIL
days-until-tide
17
1
11

BUTTON
1387
16
1458
49
profiler
setup                  ;; set up the model\nprofiler:start         ;; start profiling\nrepeat 10 [ go ]       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
358
586
558
736
Mean daily km
ticks
current-kcal-return
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if plots? [plotxy ticks mean_dailykm]"
"Running mean" 1.0 0 -8330359 true "" "if plots? and ticks > 0 [plotxy ticks (cum_km / nragents / ticks)]"

PLOT
560
587
760
737
coast distance
ticks
distance from coast
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if plots? and ticks > 0  [plotxy ticks mean [distance min-one-of patches with [goodcoast? = true] [distance myself]] of camps]"

SWITCH
1383
133
1486
166
plots?
plots?
1
1
-1000

CHOOSER
162
654
286
699
map-zone
map-zone
"z1" "z2" "full"
2

BUTTON
1386
57
1499
90
profiler module
profiler:start         ;; start profiling\nask agents [set time-forage-budget 5.9]\nrepeat 100 [ \nask agents [\nask pick-patch-local-tidal [set pcolor orange]\nask pick-patch-local-tidal-land-old [set pcolor yellow]\nask pick-patch-local-tidal-land [set pcolor red]\n]\n]\n       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
18
657
158
702
display-mode
display-mode
"vt" "kcal" "hybrid" "time-replenished" "times-harvested" "none"
3

BUTTON
82
215
137
248
range
  ask one-of camps [\n    ask patches-at-radius vision-camp [set pcolor red]\n    ask patches-at-radius camp-mobility [set pcolor blue]\n  ]\n\nask one-of agents [\n  ask patches-at-radius vision-forager [set pcolor yellow] \n  \n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
3
340
125
385
daily-time-budget
daily-time-budget
5.9 10
0

MONITOR
1025
57
1164
102
mean-daily-km-per-agent
mean_dailykm
0
1
11

SWITCH
4
551
126
584
global-knowledge?
global-knowledge?
0
1
-1000

BUTTON
1387
96
1500
129
profile-noreset
profiler:start         ;; start profiling\nrepeat 10 [ go ]       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
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
4
180
127
213
nrcamps
nrcamps
0
30
20
1
1
NIL
HORIZONTAL

SLIDER
2
307
125
340
walk-speed
walk-speed
1
10
2
1
1
km/hr
HORIZONTAL

MONITOR
3
384
125
429
camp-mobility (in cells)
camp-mobility
1
1
11

SLIDER
4
584
127
617
max_kcal_to_harvest
max_kcal_to_harvest
0
5000
3000
1000
1
NIL
HORIZONTAL

MONITOR
1020
111
1070
156
NIL
tideday
0
1
11

SLIDER
128
272
220
305
days_of_foresight
days_of_foresight
1
5
1
1
1
NIL
HORIZONTAL

BUTTON
1020
156
1092
189
bluepicks
;ask camp 0 [repeat 100 [test4 ask pick-patch-local-tidal-foresight [set current_kcal_return 0]]]\nrepeat 100 [ask camps [test4 ask pick-patch-local-tidal-foresight [set current_kcal_return 0]]]
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
1092
156
1163
189
travel days
ask patches [set plabel \"\"]\nask camp 0 [ask n-of 100 patches in-radius vision-camp [set plabel-color blue set plabel precision (distance myself / camp-mobility) 1]]
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
1020
189
1093
222
distweight
ask patches [set plabel \"\"]\nask camp 2 [ask n-of 30 (patch-set patches in-radius vision-camp patches-coast)[set plabel round (ifelse-value (current_kcal_return > 0 or goodcoast?) [temporal_multiplier] [0] * daily-time-budget - (distance myself / camp-mobility * daily-time-budget * current_kcal_return ))]]\nask camp 2 [test4]\n;ask camp 2 [inspect pick-patch-local-tidal-foresight]
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
124
307
187
340
mob
set camp-mobility daily-time-budget * walk-speed * 10 * .75
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
138
214
219
274
discount_rate
0.1
1
0
Number

SLIDER
126
147
218
180
hunter-percent
hunter-percent
0
1
0.5
.1
1
NIL
HORIZONTAL

MONITOR
1005
346
1062
391
hunters
count hunters
0
1
11

MONITOR
1062
346
1119
391
gathers
count gathers
0
1
11

BUTTON
126
76
189
109
NIL
hunt
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
1020
222
1093
255
dw forager
ask patches [set plabel \"\"]\nask agent 10 [\nset time-forage-budget 5.9\nask n-of 30 (patch-set patches in-radius vision-camp patches-coast) with [vt > 0] [\n  set plabel round (\n      max (list \n        ;marine: if (daily-left) + travel < tide, tide - (daily-left) - travel, 0\n        ((current_kcal_return * (ifelse-value ((daily-time-budget - [time-forage-budget] of myself) + (time-walk-cell * distance myself) < 2) [2 - (daily-time-budget - [time-forage-budget] of myself) - (time-walk-cell * distance myself)][0])) + \n        ;terrestrial: if (daily-left) + travel < tide, daily-tide, left-travel\n          ([current_kcal_return] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * \n            ifelse-value ((daily-time-budget - [time-forage-budget] of myself) + (time-walk-cell * distance myself) < 2) [daily-time-budget - 2] [[time-forage-budget] of myself - (time-walk-cell * distance myself)] \n            ))\n        (ifelse-value (goodcoast? AND current_kcal_return > 0) [kcal_return_min] [current_kcal_return] * ([time-forage-budget] of myself - (time-walk-cell * distance myself)))\n      ))\n]\n]\n\nask agent 10 [ask pick-patch-local-tidal-land [\n  set plabel round (\n      max (list \n        ;marine: if (daily-left) + travel < tide, tide - (daily-left) - travel, 0\n        ((current_kcal_return * (ifelse-value ((daily-time-budget - [time-forage-budget] of myself) + (time-walk-cell * distance myself) < 2) [2 - (daily-time-budget - [time-forage-budget] of myself) - (time-walk-cell * distance myself)][0])) + \n        ;terrestrial: if (daily-left) + travel < tide, daily-tide, left-travel\n          ([current_kcal_return] of one-of patches in-radius 2 with [vt > 0 AND vt < 10] * \n            ifelse-value ((daily-time-budget - [time-forage-budget] of myself) + (time-walk-cell * distance myself) < 2) [daily-time-budget - 2] [[time-forage-budget] of myself - (time-walk-cell * distance myself)] \n            ))\n        (ifelse-value (goodcoast? AND current_kcal_return > 0) [kcal_return_min] [current_kcal_return] * ([time-forage-budget] of myself - (time-walk-cell * distance myself)))\n      ))\n]\n]\nask agent 10 [test3]\n
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
4
617
127
650
camp-move-threshold
camp-move-threshold
0
5000
1500
100
1
NIL
HORIZONTAL

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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="zooms_map" repetitions="5" runMetricsEveryStep="false">
    <setup>reset-timer
setup</setup>
    <go>go</go>
    <timeLimit steps="3650"/>
    <exitCondition>count patches with [current_kcal_return &gt; 0] &lt; (count agents)</exitCondition>
    <metric>kcal-avg</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 1]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 2]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 3]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 4]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 5]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 6]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 7]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 8]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 9]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 10]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 11]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt &gt;= 12]</metric>
    <metric>mean [days_without] of camps / ticks</metric>
    <metric>mean [days_without] of agents / ticks</metric>
    <metric>timer</metric>
    <enumeratedValueSet variable="camps?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nrcamps">
      <value value="7"/>
      <value value="5"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nragents">
      <value value="15"/>
      <value value="10"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="map-zone">
      <value value="&quot;z1&quot;"/>
      <value value="&quot;z2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-knowledge?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="walk-speed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-time-budget">
      <value value="5.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forager-movement">
      <value value="&quot;local-patch-choice&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-foresight">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-forager">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-camp">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;kcal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_foresight">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount_rate">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plots?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="full_map" repetitions="5" runMetricsEveryStep="false">
    <setup>reset-timer
setup</setup>
    <go>go</go>
    <timeLimit steps="3650"/>
    <metric>kcal-avg</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 1]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 2]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 3]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 4]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 5]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 6]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 7]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 8]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 9]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 10]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 11]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt &gt;= 12]</metric>
    <metric>mean [days_without] of camps / ticks</metric>
    <metric>mean [days_without] of agents / ticks</metric>
    <metric>timer</metric>
    <enumeratedValueSet variable="camps?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nrcamps">
      <value value="25"/>
      <value value="20"/>
      <value value="15"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nragents">
      <value value="30"/>
      <value value="20"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="map-zone">
      <value value="&quot;full&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-knowledge?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="walk-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-time-budget">
      <value value="5.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forager-movement">
      <value value="&quot;local-patch-choice&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-foresight">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-forager">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-camp">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;kcal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_foresight">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount_rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_kcal_to_harvest">
      <value value="3000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="camp-move-threshold">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plots?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="full_map_single" repetitions="1" runMetricsEveryStep="false">
    <setup>reset-timer
setup</setup>
    <go>go</go>
    <timeLimit steps="3650"/>
    <metric>kcal-avg</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 1]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 2]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 3]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 4]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 5]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 6]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 7]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 8]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 9]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 10]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 11]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt &gt;= 12]</metric>
    <metric>mean [days_without] of camps / ticks</metric>
    <metric>mean [days_without] of agents / ticks</metric>
    <metric>timer</metric>
    <enumeratedValueSet variable="camps?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nrcamps">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nragents">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="map-zone">
      <value value="&quot;full&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-knowledge?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="walk-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-time-budget">
      <value value="5.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forager-movement">
      <value value="&quot;local-patch-choice&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-foresight">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-forager">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-camp">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;kcal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_foresight">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount_rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_kcal_to_harvest">
      <value value="3000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="camp-move-threshold">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plots?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment3" repetitions="1" runMetricsEveryStep="true">
    <setup>reset-timer
setup</setup>
    <go>repeat 30 [go]</go>
    <timeLimit steps="120"/>
    <metric>kcal-avg</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 1]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 2]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 3]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 4]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 5]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 6]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 7]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 8]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 9]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 10]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt = 11]</metric>
    <metric>sum [times-harvested * kcal_return] of patches with [vt &gt;= 12]</metric>
    <metric>mean [days_without] of camps / ticks</metric>
    <metric>mean [days_without] of agents / ticks</metric>
    <metric>timer</metric>
    <metric>mean [distance min-one-of patches with [goodcoast? = true] [distance myself]] of camps</metric>
    <enumeratedValueSet variable="walk-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="map-zone">
      <value value="&quot;full&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nragents">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_kcal_to_harvest">
      <value value="3000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_foresight">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plots?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-camp">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;time-replenished&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-knowledge?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount_rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-time-budget">
      <value value="5.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nrcamps">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-foresight">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-forager">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="camp-move-threshold">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-percent">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forager-movement">
      <value value="&quot;local-patch-choice&quot;"/>
    </enumeratedValueSet>
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
