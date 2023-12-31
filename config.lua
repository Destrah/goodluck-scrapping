TaxiConfig = {}

TaxiConfig.TaxiModel = "taxi"

TaxiConfig.TaxiDepos = {
    {
        x = 903.9481,
        y = -173.5247,
        z = 74.0756,
        spawn = {x = 913.8768, y = -167.0843, z = 74.33028, h = 147.51924133301}
    },
}

XTowConfig = {}

---------------------------------------------------------------------------
-- TOWTRUCK MODEL
---------------------------------------------------------------------------
XTowConfig.TruckModel = "flatbed"

---------------------------------------------------------------------------
-- LOCATIONS TO GET TRUCK
---------------------------------------------------------------------------
XTowConfig.TruckDepos = {
    {
        x = -193.54,
        y = -1170.25,
        z = 23.16,
        spawn = {x = -190.98, y = -1180.90, z = 23.04, h = 90.42},
        name = 'Tow Yard'
    },
}

---------------------------------------------------------------------------
-- LOCATIONS TO IMPOUND VEHICLES
---------------------------------------------------------------------------
XTowConfig.Impounds = {
    {x = -240.27, y = -1175.75, z = 23.04}
}

XTowConfig.Repos = {
    {x = -240.27, y = -1175.75, z = 23.04}
}

XTowConfig.AIRequestLocations = {
    {vector4(-3023.97, 92.89, 11.2, 320.65), 1},
    {vector4(-3051.89, 148.4, 11.16, 181.45), 2},
    {vector4(-2812.53, 25.74, 14.49, 246.71), 3},
    {vector4(-2169.65, -372.54, 12.66, 173.35), 4},
    {vector4(-2137.33, -400.02, 12.83, 26.35), 5},
    {vector4(-2078.26, -328.3, 12.73, 84.09), 6},
    {vector4(-2026.57, -468.67, 11.01, 151.2), 7},
    {vector4(-1998.91, -514.71, 11.34, 233.88), 8},
    {vector4(-1842.52, -507.93, 27.28, 271.84), 9},
    {vector4(-1713.47, -501.11, 37.73, 328.52), 10},
    {vector4(-1699.62, -400.65, 45.92, 320.11), 11},
    {vector4(-1624.4, -328.41, 50.3, 316.59), 12},
    {vector4(-1553.14, -320.51, 46.45, 324.87), 13},
    {vector4(-1537.57, -316.56, 47.17, 321.08), 14},
    {vector4(-1389.94, -275.37, 42.68, 310.63), 15},
    {vector4(-1350.28, -246.58, 42.2, 67.21), 16},
    {vector4(-1379.52, -204.63, 44.65, 37.41), 17},
    {vector4(-1433.18, -170.13, 47.1, 125.17), 18},
    {vector4(-1295.41, -76.12, 46.41, 240.65), 19},
    {vector4(-1110.13, -157.46, 38.23, 242.09), 20},
    {vector4(949.83, -1802.08, 30.71, 182.34), 21},
    {vector4(943.31, -2053.1, 29.75, 174.33), 22},
    {vector4(804.59, -2054.44, 28.78, 87.85), 23},
    {vector4(777.25, -2047.31, 28.86, 80.43), 24},
    {vector4(728.98, -2005.07, 28.88, 76.98), 25},
    {vector4(529.47, -2032.02, 27.07, 94.47), 26},
    {vector4(337.88, -1885.05, 25.46, 326.78), 27},
    {vector4(399.83, -1766.03, 28.77, 50.78), 28},
    {vector4(345.09, -1720.03, 28.79, 54.92), 29},
    {vector4(292.04, -1688.46, 28.81, 51.91), 30},
    {vector4(218.84, -1634.79, 28.84, 231.71), 31},
    {vector4(169.29, -1556.65, 28.82, 124.98), 32},
    {vector4(96.61, -1527.17, 28.85, 53.28), 33},
    {vector4(-6.38, 193.41, 101.86, 70.22), 34},
    {vector4(-3.63, 131.71, 86.97, 159.16), 35},
    {vector4(-42.85, 5.04, 71.3, 345.62), 36},
    {vector4(-34.27, -93.17, 56.86, 340.15), 37},
    {vector4(13.42, -155.19, 55.51, 250.38), 38},
    {vector4(99.34, -201.69, 54.12, 158.62), 39},
    {vector4(209.35, -159.97, 56.49, 249.47), 40},
    {vector4(298.38, -184.71, 61.16, 140.25), 41},
    {vector4(892.61, -59.49, 78.35, 334.29), 42},
    {vector4(911.9, -14.61, 78.35, 56.59), 43},
    {vector4(1112.82, 294.28, 88.87, 291.35), 44},
    {vector4(661.49, 624.4, 128.5, 336.56), 45},
    {vector4(700.8, 613.34, 128.5, 246.06), 46},
    {vector4(-809.79, 710.2, 146.37, 89.21), 47},
    {vector4(-123.62, 511.65, 142.18, 82.82), 48},
    {vector4(1843.42, 3664.09, 33.62, 300.41), 49},
    {vector4(589.18, 2734.92, 41.65, 275.93), 50},
    {vector4(-1798.69, 793.35, 138.07, 317.78), 51},
    {vector4(-1044.44, -2526.93, 13.37, 152.9), 52},
    {vector4(-1005.32, -2621.26, 14.38, 152.14), 53},
    {vector4(-983.07, -2585.72, 15.96, 94.35), 54},
    {vector4(-935.59, -2461.57, 13.42, 294.42), 55},
}

XTowConfig.ScrapTruck = "flatbed"

XTowConfig.ScrapLocation = vector3(-525.52, -1711.47, 18.32)

XTowConfig.ScrapTruckSpawnLocation = vector4(-529.64, -1716.77, 18.32, 237.48)

XTowConfig.ScrapperSpawn = vector4(-537.53, -1720.69, 18.45, 315.8)

XTowConfig.ScrapVehicle = {
    {
        'adder',
        'sultan',
        'baller',
        'dominator',
        'dominator3',
        'gauntlet',
        'Stratum',
        'Primo',
        'Premier',
        'Radi',
        'Cavalcade',
        'RancherXL',
        'Tampa',
        'Phoenix',
        'Ingot',
        'Glendale',
        'Fugitive',
        'Asterope',
        'Washington',
        'Stanier',
        'Feltzer2',
        'Feltzer3',
        'Schafter2',
        'Peyote',
        'Mesa',
        'Mesa2',
        'Brawler',
        'Rebel',
        'RancherXL2',
        'BfInjection',
        'Voodoo',
        'Voodoo2',
        'Virgo3',
        'Virgo2',
        'Virgo',
    },
    {
        "bulldozer",
        "Mixer",
        "Mixer2",
        "Rubble",
        "TipTruck",
        "guardian",
    },
    {
        "bulldozer",
        "Mixer",
        "Mixer2",
        "Rubble",
        "TipTruck",
        "guardian",
    },
    {
        "bulldozer",
        "Mixer",
        "Mixer2",
        "Rubble",
        "TipTruck",
        "guardian",
    }
}

XTowConfig.ScrapSpawnLocations = {
    {
        {vector4(-195.1, -1522.41, 32.37, 316.97), 1},
        {vector4(-551.77, 830.24, 197.00, 345.75), 2},
        {vector4(891.52, -1937.69, 29.6, 225.92), 3},
        {vector4(860.22, -867.78, 24.52, 174.36), 4},
        {vector4(-491.85, -574.08, 24.47, 266.19), 5},
        {vector4(158.96, -257.06, 50.4, 104.19), 6},
        {vector4(138.4, -243.61, 50.53, 185.17), 7},
        {vector4(492.35, -266.78, 46.23, 321.81), 8},
        {vector4(-251.04, -2069.13, 26.62, 304.66), 9},
        {vector4(198.24, -3127.0, 4.79, 354.4), 10},
        {vector4(1112.08, 227.0, 79.99, 328.32), 11},
        {vector4(425.12, 248.0, 102.21, 264.73), 12},
        {vector4(494.6, -1006.63, 26.88, 355.8), 13},
        {vector4(230.22, -912.91, 26.68, 143.76), 14},
        {vector4(467.98, -1063.67, 28.21, 270.45), 15},
        {vector4(-1109.19, -1244.05, 1.43, 26.89), 16},
        {vector4(-1049.03, -2540.78, 12.68, 145.39), 17},
        {vector4(-134.18, -781.81, 31.57, 95.93), 18},
        {vector4(-106.83, -605.42, 35.27, 124.43), 19},
        {vector4(302.82, -689.66, 28.32, 158.65), 20},
        {vector4(898.15, -600.35, 56.65, 328.69), 21},
        {vector4(1067.45, -781.05, 57.26, 355.79), 22},
        {vector4(-1617.71, -926.97, 7.68, 135.86), 23},
        {vector4(-1659.33, -898.05, 7.59, 51.42), 24},
        {vector4(-2332.7, 386.46, 173.6, 114.76), 25},
        {vector4(-789.78, 859.86, 202.16, 124.86), 26},
        {vector4(602.9, 2722.86, 40.89, 2.67), 27},
        {vector4(1268.44, -3089.61, 4.9, 81.55), 28},
        {vector4(4.55, -386.06, 38.39, 167.23), 29},
        {vector4(572.44, -101.4, 66.34, 355.5), 30},
        {vector4(454.81, -754.39, 26.36, 178.68), 31},
        {vector4(890.8, -1588.02, 29.35, 153.4), 32},
        {vector4(-837.88, -39.24, 38.2, 297.63), 33},
        {vector4(-443.4, 180.52, 74.2, 334.81), 34},
        {vector4(135.68, 273.73, 108.97, 338.91), 35},
        {vector4(-380.19, -277.17, 33.32, 36.6), 36},
        {vector4(-891.04, -206.19, 37.68, 38.16), 37},
        {vector4(-1314.02, -1258.42, 3.57, 83.32), 38},
        {vector4(-1307.86, -1246.82, 3.68, 227.07), 39},
        {vector4(-1171.41, -896.56, 12.85, 333.23), 40},
        {vector4(-344.71, 73.07, 62.63, 80.41), 41},
        {vector4(571.7, -2754.22, 5.06, 147.43), 42},
        {vector4(474.89, -2940.77, 5.04, 350.53), 43},
        {vector4(-993.5, -293.38, 36.84, 200.75), 44},
        {vector4(-962.76, -340.66, 36.62, 87.79), 45},
        {vector4(-1135.45, -335.13, 36.67, 351.86), 46},
        {vector4(-1289.51, -420.32, 34.0, 187.26), 47},
        {vector4(899.31, -48.16, 77.76, 320.9), 48},
        {vector4(936.12, -2368.31, 29.53, 80.06), 49},
        {vector4(880.12, -2196.64, 29.52, 32.04), 50},
        {vector4(1131.99, -2357.83, 30.11, 32.97), 51},
        {vector4(1196.9, -2270.94, 29.52, 91.05), 52},
        {vector4(1302.98, -1934.75, 42.26, 115.06), 53},
        {vector4(70.49, 24.37, 68.44, 67.31), 54},
    },
    {
        {vector4(1386.02, -2123.1, 54.26, 140.88), 1000},
        {vector4(-149.75, -1043.23, 26.86, 250.98), 1001},
        {vector4(-481.49, -904.61, 23.51, 159.38), 1002},
        {vector4(109.24, -446.18, 40.72, 323.2), 1003},
        {vector4(1372.38, -730.66, 66.72, 102.92), 1004},
        {vector4(1092.74, -2423.86, 29.95, 177.91), 1005},
        {vector4(1092.73, 2105.55, 52.97, 320.59), 1006},
        {vector4(1484.2, -2375.64, 71.52, 134.2), 1007},
        {vector4(-103.59, -1016.71, 26.86, 250.61), 1008},
    },
    {
        {vector4(1386.02, -2123.1, 54.26, 140.88), 2000},
        {vector4(-149.75, -1043.23, 26.86, 250.98), 2001},
        {vector4(-481.49, -904.61, 23.51, 159.38), 2002},
        {vector4(109.24, -446.18, 40.72, 323.2), 2003},
        {vector4(1372.38, -730.66, 66.72, 102.92), 2004},
        {vector4(1092.74, -2423.86, 29.95, 177.91), 2005},
        {vector4(1092.73, 2105.55, 52.97, 320.59), 2006},
        {vector4(1484.2, -2375.64, 71.52, 134.2), 2007},
        {vector4(-103.59, -1016.71, 26.86, 250.61), 2008},
    },
    {
        {vector4(1386.02, -2123.1, 54.26, 140.88), 2000},
        {vector4(-149.75, -1043.23, 26.86, 250.98), 2001},
        {vector4(-481.49, -904.61, 23.51, 159.38), 2002},
        {vector4(109.24, -446.18, 40.72, 323.2), 2003},
        {vector4(1372.38, -730.66, 66.72, 102.92), 2004},
        {vector4(1092.74, -2423.86, 29.95, 177.91), 2005},
        {vector4(1092.73, 2105.55, 52.97, 320.59), 2006},
        {vector4(1484.2, -2375.64, 71.52, 134.2), 2007},
        {vector4(-103.59, -1016.71, 26.86, 250.61), 2008},
    }
}

---------------------------------------------------------------------------
-- BLACKLISTED VEHICLES THAT CAN'T BE TOWED
---------------------------------------------------------------------------
XTowConfig.BlacklistedVehicles = {
    "bus",
    "cargobob",
    "cargobob2",
    "cargobob3",
    "cargobob4",
    "cargoplane",
    "Rhino",
    "pbus",
    "firetruk",
    "nimbus",
    "rentalbus",
    "tourbus",
    "airbus",
    "blimp",
    "blimp2",
    "coach",
    "cutter",
    "dinghy",
    "dinghy2",
    "dinghy3",
    "dinghy4",
    "dodo",
    "duster",
    "insurgent",
    "insurgent2",
    "lazer",
    "limo2",
    "luxor",
    "luxor2",
    "mammatus",
    "marquis",
    "marshall",
    "mixer",
    "mixer2",
    "monster",
    "mule",
    "mule2",
    "mule3",
    "packer",
    "phantom",
    "pounder",
    "predator",
    "rallytruck",
    "ripley",
    "romero",
    "rubble",
    "savage",
    "shamal",
    "skylift",
    "speeder",
    "speeder2",
    "squalo",
    "submersible",
    "submersible2",
    "suntrap",
    "supervolito",
    "superbolito2",
    "swift",
    "swift2",
    "tiptruck",
    "tiptruck2",
    "titan",
    "toro",
    "toro2",
    "tropic",
    "tropic2",
    "tug",
    "valkyrie",
    "valkyrie2",
    "velum",
    "velum2",
    "vigero",
    "volatus"
}