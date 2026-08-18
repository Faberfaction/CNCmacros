%
O9010 (5-AXIS TORUS GROOVE CONTOUR - REV 3)
(HAAS NGC  |  G234 TCPC  |  IMPERIAL G20)
(SADDLE GROOVE - BC TABLE - XYZ HEAD)
(============================================================)
( SINGLE TOOL CENTER PATH ON TORUS SURFACE                  )
( FEED AND SPEED SET BY CALLER BEFORE G65 CALL              )
( CALL THREE TIMES FOR ROUGH + TWO FINISH WALLS             )
(============================================================)
( GEOMETRY - CORRECTED FOR I<>J CASE:                       )
(                                                            )
(  THETA = geometric angle, always positive 0->A            )
(  C_out = THETA * DIR  (signed for direction)              )
(  phi   = ASIN(I/J * SIN(C_out))  (minor arc elevation)   )
(  X     = Xctr + I * COS(C_out)                            )
(  Y     = Yctr + I * SIN(C_out)                            )
(  Z     = -J * (1 - COS(phi))                              )
(  B     = phi * DIR                                         )
(                                                            )
( SADDLE CONVENTION:                                         )
(  THETA=0   TOP     B=0     TOOL VERTICAL   Z=0            )
(  THETA=90  SIDE    B=MAX   MAX TILT                       )
(  THETA=180 BOTTOM  B=0     TOOL VERTICAL   Z=MIN          )
(  THETA=270 SIDE    B=-MAX  MAX TILT OTHER WAY             )
(                                                            )
( MAX B TILT = ASIN(I/J) DEGREES                            )
( MAX Z DEPTH = -J*(1-COS(ASIN(I/J)))                       )
(============================================================)
( ARGUMENT MAP:                                              )
(                                                            )
(  A = TOTAL ARC TO TRAVEL (deg)  [#1]  default 360         )
(  H = TOOL LENGTH OFFSET NUMBER  [#11]                     )
(  I = XY CIRCLE RADIUS (in.)     [#4]  tool centerline     )
(  J = XZ MINOR ARC RADIUS (in.)  [#5]  torus profile       )
(  P = DIRECTION 0=CCW / 1=CW     [#16] default 0           )
(  Q = CHORD ERROR TOL (in.)      [#17] default .001        )
(  R = RETRACT PLANE (in.)        [#18]                     )
(  V = RAMP FLAG 0=NONE / 1=RAMP  [#22] default 0           )
(  W = RAMP LENGTH (deg of C)     [#23] default 45          )
(  X = CENTER X (in.)             [#24] default 0           )
(  Y = CENTER Y (in.)             [#25] default 0           )
(============================================================)
( EXAMPLE CALLS:                                            )
(                                                            )
( ROUGH - CENTERLINE I=1.165, J=5.197, RAMP ENTRY:         )
(  S1200 M3                                                  )
(  G94 F8.                                                   )
(  G65 P9010 A360 H1 I1.165 J5.197 P0 R1. V1 W45           )
(                                                            )
( FINISH WALL 1 - INNER RADIUS (I - tool radius):           )
(  G94 F4.                                                   )
(  G65 P9010 A360 H1 I1.040 J5.197 P0 R1.                  )
(                                                            )
( FINISH WALL 2 - OUTER RADIUS (I + tool radius):           )
(  G94 F4.                                                   )
(  G65 P9010 A360 H1 I1.290 J5.197 P1 R1.                  )
(============================================================)
( INTERNAL VARIABLES: #100-#149                             )
( DO NOT USE #100-#149 IN CALLING PROGRAM WHILE ACTIVE      )
(============================================================)

(--- ARGUMENT VALIDATION ---)
IF [#4  EQ #0] THEN #3000 = 1  (MISSING I: XY RADIUS)
IF [#5  EQ #0] THEN #3000 = 2  (MISSING J: XZ RADIUS)
IF [#11 EQ #0] THEN #3000 = 3  (MISSING H: TOOL OFFSET)
IF [#18 EQ #0] THEN #3000 = 4  (MISSING R: RETRACT PLANE)
IF [#4 LE 0.0] THEN #3000 = 5  (I MUST BE POSITIVE)
IF [#5 LE 0.0] THEN #3000 = 6  (J MUST BE POSITIVE)

(--- VALIDATE I < J ---) 
( I must be less than J or ASIN(I/J) would exceed 90 deg   )
IF [#4 GE #5] THEN #3000 = 7   (I MUST BE LESS THAN J)

(--- DEFAULTS ---)
IF [#1  EQ #0] THEN #1  = 360.0
IF [#16 EQ #0] THEN #16 = 0
IF [#17 EQ #0] THEN #17 = 0.001
IF [#22 EQ #0] THEN #22 = 0
IF [#23 EQ #0] THEN #23 = 45.0
IF [#24 EQ #0] THEN #24 = 0.0
IF [#25 EQ #0] THEN #25 = 0.0

(--- VALIDATE ARC ---)
IF [#1 LE 0.0]   THEN #3000 = 8  (A MUST BE POSITIVE)
IF [#1 GT 360.0] THEN #3000 = 9  (A CANNOT EXCEED 360)
IF [#22 EQ 1] THEN
  IF [#23 GE #1] THEN #3000 = 10 (RAMP LENGTH EXCEEDS TOTAL ARC)
ENDIF

(============================================================)
( DIRECTION SIGN                                             )
( CCW: C increases positively  DIR = +1                     )
( CW:  C increases negatively  DIR = -1                     )
(============================================================)
IF [#16 EQ 0] THEN #103 = 1.0
IF [#16 EQ 1] THEN #103 = -1.0

(============================================================)
( ANGULAR STEP FROM CHORD ERROR                             )
( Use smaller of I and J as governing radius                )
( step = 2 * ACOS(1 - Q/Rmin)                              )
(============================================================)
#100 = #4
IF [#5 LT #100] THEN #100 = #5
#101 = 1.0 - [#17 / #100]
IF [#101 LT -1.0] THEN #101 = -1.0
IF [#101 GT  1.0] THEN #101 =  1.0
#102 = 2.0 * ACOS[#101]
IF [#102 GT 5.0]  THEN #102 = 5.0
IF [#102 LT 0.01] THEN #102 = 0.01

(============================================================)
( DERIVED GEOMETRY                                           )
( phi_max = ASIN(I/J) - max minor arc elevation angle       )
( Stored for reference / ramp scaling                       )
(============================================================)
#105 = ASIN[#4 / #5]           (PHI MAX IN RADIANS - NOT USED IN LOOP)
                                (LOOP USES DEGREES THROUGHOUT)

(============================================================)
( MODAL SETUP                                               )
(============================================================)
G20 G90 G94
G49
G00 Z#18
G00 B0. C0.

(--- START POSITION: TOP OF SADDLE ---) 
( Theta=0: X=Xctr+I, Y=Yctr, Z=0, B=0, C=0               )
#110 = #24 + #4
#111 = #25
G00 X#110 Y#111

(--- ACTIVATE TCPC ---)
G234 H#11

G00 X#110 Y#111 Z#18 B0. C0.

(============================================================)
( RAMP ENTRY OR DIRECT FEED TO SURFACE                      )
(============================================================)
IF [#22 NE 1] GOTO 20

(--- RAMP ENTRY: SPIRAL INTO CUT OVER W DEGREES OF C ---)
( Z and B interpolate from 0 to their full torus values     )
( scaled linearly by ramp fraction (theta/W)                )
( Fine step during ramp for smooth entry                    )
#120 = 0.0
#121 = #102
IF [#121 GT 2.0] THEN #121 = 2.0

WHILE [#120 LT #23] DO1
  #120 = #120 + #121
  IF [#120 GT #23] THEN #120 = #23

  ( Signed C output                                         )
  #125 = #120 * #103

  ( XY position                                             )
  #126 = #24 + #4 * COS[#125]
  #127 = #25 + #4 * SIN[#125]

  ( phi at this C: clamp argument to [-1,1] for ASIN safety )
  #128 = #4 / #5 * SIN[#125]
  IF [#128 GT  1.0] THEN #128 =  1.0
  IF [#128 LT -1.0] THEN #128 = -1.0
  #129 = ASIN[#128]              (PHI IN RADIANS)
  #129 = #129 * 180.0 / ACOS[-1.0]  (CONVERT TO DEGREES)
  (NOTE: ACOS[-1]=PI so 180/ACOS[-1] = 180/PI = deg/rad)

  ( Full torus Z and B at this point                        )
  #134 = 0.0 - [#5 * [1.0 - COS[#129]]]   (FULL Z)
  #135 = #129 * #103                        (FULL B)

  ( Scale linearly by ramp fraction                         )
  #136 = #120 / #23              (RAMP FRACTION 0->1)
  #137 = #134 * #136             (RAMPED Z)
  #138 = #135 * #136             (RAMPED B)

  G01 X#126 Y#127 Z#137 B#138 C#125

END1
GOTO 21

(--- NO RAMP: FEED TO SURFACE AT TOP OF SADDLE ---)
N20
G01 X#110 Y#111 Z0. B0. C0.

N21
(============================================================)
( MAIN CONTOUR LOOP                                         )
(============================================================)
( #140 = geometric angle theta (always positive, 0 -> A)   )
( #141 = signed C output = theta * DIR                      )
( #142 = ASIN argument (clamped)                            )
( #143 = phi in degrees (minor arc elevation)               )
( #144 = X                                                  )
( #145 = Y                                                  )
( #146 = Z = -J*(1-COS(phi))                               )
( #147 = B = phi * DIR                                      )
(============================================================)
IF [#22 EQ 1] THEN #140 = #23
IF [#22 NE 1] THEN #140 = 0.0

WHILE [#140 LT #1] DO2

  #140 = #140 + #102
  IF [#140 GT #1] THEN #140 = #1

  ( Signed C output                                         )
  #141 = #140 * #103

  ( XY: use signed C so circle direction is correct         )
  #144 = #24 + #4 * COS[#141]
  #145 = #25 + #4 * SIN[#141]

  ( phi: ASIN(I/J * SIN(C_signed))                         )
  ( Clamp argument to [-1,1] to guard against float error   )
  #142 = #4 / #5 * SIN[#141]
  IF [#142 GT  1.0] THEN #142 =  1.0
  IF [#142 LT -1.0] THEN #142 = -1.0
  #143 = ASIN[#142]              (PHI IN RADIANS)
  #143 = #143 * 180.0 / ACOS[-1.0]  (PHI IN DEGREES)

  ( Z from phi                                              )
  #146 = 0.0 - [#5 * [1.0 - COS[#143]]]

  ( B = phi * DIR                                           )
  #147 = #143 * #103

  G01 X#144 Y#145 Z#146 B#147 C#141

END2

(============================================================)
( RETRACT AND CANCEL TCPC                                   )
(============================================================)
G49                             (CANCEL TCPC)
G00 Z#18                        (RETRACT Z)
G00 B0. C0.                     (HOME ROTARIES)
G43 H#11                        (RESTORE STANDARD TLO)
M99
%
