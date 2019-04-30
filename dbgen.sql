PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS QRTag;
DROP TABLE IF EXISTS Building;
DROP TABLE IF EXISTS Floor;
DROP TABLE IF EXISTS IndoorLocation;
DROP TABLE IF EXISTS Staircase;

CREATE TABLE QRTag (
    url VARCHAR,
    xcoord REAL NOT NULL,
    ycoord REAL NOT NULL,
    PRIMARY KEY (url)
    );

CREATE TABLE Building (
    alias VARCHAR,
    name VARCHAR NOT NULL UNIQUE,
    floors INTEGER NOT NULL,
    hasLGF BOOLEAN NOT NULL, -- has (l)ower (g)round (f)loor
    delta REAL NOT NULL,
    xscale REAL NOT NULL, -- scale columns for plane size
    yscale REAL NOT NULL,
    compassOffset REAL NOT NULL, -- in degrees
    PRIMARY KEY (alias)
    );

CREATE TABLE Floor (
    bldg VARCHAR,
    level INTEGER,
    PRIMARY KEY (bldg, level),
    FOREIGN KEY (bldg) REFERENCES Building --(alias)
        ON UPDATE CASCADE
        ON DELETE CASCADE
    );

CREATE TABLE Staircase (
    bldg VARCHAR,
    xcoord REAL NOT NULL,
    ycoord REAL NOT NULL,
    PRIMARY KEY (bldg, xcoord, ycoord),
    FOREIGN KEY (bldg) REFERENCES Building --(alias)
        ON UPDATE CASCADE
        ON DELETE CASCADE
    );

CREATE TABLE IndoorLocation (
    bldg VARCHAR,
    level INTEGER,
    title VARCHAR,
    subtitle VARCHAR,
    xcoord REAL NOT NULL,
    ycoord REAL NOT NULL,
    PRIMARY KEY (bldg, level, title),
    FOREIGN KEY (bldg, level) REFERENCES Floor --(bldg, level)
        ON UPDATE CASCADE
        ON DELETE CASCADE
    );

INSERT INTO QRTag VALUES 
    -- Format: Building::FloorLevel::Point
    ("UP ITDC::1::A", 0.0, 0.0),
    ("UP ITDC::2::A", 0.0, 0.0),
    ("UP ITDC::3::A", 0.0, 0.0),
    ("Melchor Hall::1::A", 0.0, 0.0),
    ("Melchor Hall::2::A", 0.0, 0.0),
    ("Melchor Hall::3::A", 0.0, 0.0),

    ("UP AECH::2::Entrance", -0.031, -0.201),
    ("UP AECH::2::ColumnL", -1.41, -0.341),
    ("UP AECH::2::ColumnR", 1.468, -0.341),
    ("UP AECH::2::TLC", 1.07, 0.805),
    ("UP AECH::3::ColumnL", -1.42, -0.306),
    ("UP AECH::3::ColumnR", 1.505, -0.306),
    ("UP AECH::3::CLR1", -2.3, 0.136),
    ("UP AECH::3::LecHall", -2.75, 0.782),
    ("UP AECH::3::WSG", 0.04, 0.187),
    ("UP AECH::3::TL1", -0.822, 1.016),
    ("UP AECH::3::BB", -0.497, 1.162),
    ("UP AECH::3::CLR4", 2.099, 0.729),
    ("UP AECH::3::ERDT", 0.836, 0.749),
    ("UP AECH::4::ColumnL", -0.907, -0.123),
    ("UP AECH::4::ColumnR", 0.954, -0.123),
    ("UP AECH::4::Admin", 0.038, -0.079),
    ("UP AECH::4::Conference", 0.038, 1.143),
    ("UP AECH::4::CSG", 2.404, 0.081),
    ("UP AECH::4::CVMIG", -1.587, 0.245)

    ("UP ITDC::1::Entrance", -1.921, -0.281),
    ("UP ITDC::1::FemaleCR", 1.109, -0.571),
    ("UP ITDC::1::NorthStairs", 1.463, 0.233),
    ("UP ITDC::2::209R", 1.088, -0.562),
    ("UP ITDC::2::207Door", 0.129, -0.562),
    ("UP ITDC::2::205BB203", -0.43, -0.562),
    ("UP ITDC::2::FloorDirectory", -1.951, -0.562),
    ("UP ITDC::2::208BB210", -0.534, 0.495),
    ("UP ITDC::2::212L", 0.187, 0.495),
    ("UP ITDC::2::UnderExitStairsN", 1.451, 0.233),
    ("UP ITDC::3::303L", 0.028, -0.564),
    ("UP ITDC::3::301", -1.009, -0.578),
    ("UP ITDC::3::FAlarmStairsS", -1.86, -0.451),
    ("UP ITDC::3::304", -1.89, 0.502),
    ("UP ITDC::3::308B", -0.253, 0.513),
    ("UP ITDC::3::312", 1.082, 0.508);

INSERT INTO Building VALUES
    ("UP AECH", "UP Alumni Engineers Centennial Hall", 4, TRUE, 3.0 - 0.2, 7.995, 4.086, 95),
    ("UP ITDC", "UP Information Technology Development Center", 3, FALSE, 3.6 - 0.2, 5.781, 3.8, 0),
    ("MH", "Melchor Hall", 5, FALSE, 4.4 - 0.2, 12.595, 6.271, 0),
    ("MainLib", "University Main Library", 4, TRUE, 5.2 - 0.2, 10.0, 6.0, 0);
INSERT INTO Floor VALUES
    ("UP AECH", 1),
    ("UP AECH", 2),
    ("UP AECH", 3),
    ("UP AECH", 4),
    ("UP ITDC", 1),
    ("UP ITDC", 2),
    ("UP ITDC", 3),
    ("MH", 1),
    ("MH", 2),
    ("MH", 3),
    ("MH", 4),
    ("MH", 5);
INSERT INTO Staircase VALUES
    ("UP AECH", -1.116, -0.578),
    ("UP AECH", 1.199, -0.578),
    ("UP ITDC", 1.46, -0.228),
    ("UP ITDC", -2.304, 0.115),
    ("MH", 0.103, -0.145),
    ("MH", -5.465, -0.432);
INSERT INTO IndoorLocation VALUES
    -- UP Alumni Engineers Centennial Hall
    --  Lower Ground Floor
    ("UP AECH", 1, "Engineering Library 2", "", 0.0, 0.0),
    --  Ground Floor
    ("UP AECH", 2, "Serials Section", "", -1.547, -0.23),
    ("UP AECH", 2, "The Learning Commons", "TLC", 1.129, 0.8),
    --  Second Floor
    ("UP AECH", 3, "Rm 200", "Web Science Laboratory", 0.196, 0.155),
    ("UP AECH", 3, "Rm 201", "Web Science Group (WSG)", -0.125, 0.155),
    ("UP AECH", 3, "Rm 202", "ERDT Room", 0.925, 0.85),
    ("UP AECH", 3, "Rm 203", "Classroom 2 (CLR 2)", -0.85, 0.85),
    ("UP AECH", 3, "Rm 204", "Classroom 3 (CLR 3)", 1.00, 1.45),
    ("UP AECH", 3, "Rm 205", "Teaching Lab 1 (TL1)", -0.886, 1.088),
    ("UP AECH", 3, "Rm 207", "Classroom 1 (CLR 1)", -2.229, 0.098),
    ("UP AECH", 3, "Rm 210", "Teaching Lab 3 (TL3)", 2.148, 0.516),
    ("UP AECH", 3, "Rm 211", "Accenture Ideas Exchange Room", -2.136, -0.486),
    ("UP AECH", 3, "Rm 212", "Classroom 4 (CLR 4)", 2.082, 0.823),
    ("UP AECH", 3, "Rm 214", "Teaching Lab 2 (TL2)", 2.393, 1.111),
    ("UP AECH", 3, "Rm 215", "Seminar Room", -2.604, 1.066),
    --  Third Floor
    ("UP AECH", 4, "Rm 300", "Administration Office", 0.038, 0.172),



    -- UP Information Technology Development Center
    --  Ground Floor
    ("UP ITDC", 1, "Rm 103", "", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 104", "", -1.353, 0.629),
    ("UP ITDC", 1, "Rm 105", "", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 106", "", 0.532, 0.629),
    ("UP ITDC", 1, "Rm 108", "", 1.091, 0.629),
    ("UP ITDC", 1, "Men's Room", "", 0.979, 0.348),
    ("UP ITDC", 1, "Ladies' Room", "", 0.979, -0.401),
    --  Second Floor
    ("UP ITDC", 2, "Rm 201", "Conference Room", -0.98, -0.650),
    ("UP ITDC", 2, "Rm 203", "Trainers Office", -0.724, -0.650),
    ("UP ITDC", 2, "Rm 204", "Laboratory 3", -1.791, 0.597),
    ("UP ITDC", 2, "Rm 205", "Admin Office", -0.092, -0.650),
    ("UP ITDC", 2, "Rm 206", "Server Room", -1.617, 0.597),
    ("UP ITDC", 2, "Rm 207-209", "", 0.136, -0.650),
    ("UP ITDC", 2, "Rm 208-210", "", -1.153, 0.597),
    ("UP ITDC", 2, "Rm 211", "", 1.40, -0.650),
    ("UP ITDC", 2, "Rm 212", "Laboratory 5", 0.299, 0.597),
    ("UP ITDC", 2, "Rm 213", "", 1.606, -0.571),
    ("UP ITDC", 2, "Rm 214", "Meeting Room", 0.766, 0.597),
    ("UP ITDC", 2, "Men's Room", "", 0.942, 0.300),
    ("UP ITDC", 2, "Ladies' Room", "", 0.942, -0.378),
    --  Third Floor
    ("UP ITDC", 3, "Rm 301", "Software Engineering and Information Systems Group", -1.021, -0.654),
    ("UP ITDC", 3, "Rm 303", "", -0.714, -0.654),
    ("UP ITDC", 3, "Rm 304", "", -1.787, 0.627),
    ("UP ITDC", 3, "Rm 304-B", "Office of the Director", -1.645, 0.627),
    ("UP ITDC", 3, "Rm 305", "OVPD Project Management Office", 0.141, -0.654),
    ("UP ITDC", 3, "Rm 306", "Office of the Deputy Director", -0.988, 0.627),
    ("UP ITDC", 3, "Rm 307", "", 1.659, -0.548),
    ("UP ITDC", 3, "Rm 308", "Tech Support", -0.741, 0.627),
    ("UP ITDC", 3, "Rm 308-B", "Communications", -0.129, 0.627),
    ("UP ITDC", 3, "Rm 309", "EITSC Computer Laboratory", 0.3, 0.627),
    ("UP ITDC", 3, "Rm 310", "", 0.753, 0.627),
    ("UP ITDC", 3, "Rm 312", "Infrastructure and Tech Support Group", 1.156, 0.627),
    ("UP ITDC", 3, "Men's Room", "", 0.999, 0.338),
    ("UP ITDC", 3, "Ladies' Room", "", 0.999, -0.38),



    -- College of Engineering
    --  Ground Floor
    ("MH", 1, "MH 100", "DCE Faculty Office", 1.279, -1.091),
    ("MH", 1, "MH 101", "", 1.94, -0.814),
    ("MH", 1, "MH 102", "CoMSLab (Admin)", 2.239, -1.151),
    ("MH", 1, "MH 104-106", "Rosario S. Calderon Room", 2.653, -0.794),
    ("MH", 1, "MH 105-111", "Faculty Lounge", -0.995, -0.5),
    ("MH", 1, "MH 108-110", "Environmental Systems Applications of Geomatics Engineering Research Laboratory", 3.297, -0.794),
    ("MH", 1, "MH 112-114", "", 3.94, -0.794),
    ("MH", 1, "MH 113-115", "Property Office", -2.470, -0.5),
    ("MH", 1, "MH 116", "", 4.575, -0.794),
    ("MH", 1, "MH 118", "", 4.895, -0.794),
    ("MH", 1, "MH 117", "NECFI", -3.123, -0.5),
    ("MH", 1, "MH 119-121", "", -3.77, -0.5),
    ("MH", 1, "MH 120", "", 0.0, 0.0), -- 122
    ("MH", 1, "MH 122", "DGE Instrument Room", 5.355, -0.794),
    ("MH", 1, "MH 123", "", -4.104, -0.5),
    ("MH", 1, "Male Comfort Room 1", "", -4.928, -0.5),
    ("MH", 1, "Female Comfort Room 1", "", -4.608, -0.5),
    ("MH", 1, "Male Comfort Room 2", "", 5.035, -0.794),
    --  Second Floor
    ("MH", 2, "MH 201-203", "DOST-ERDT Project Office", -0.858, -0.475),
    ("MH", 2, "MH 202", "Dean's Office", 1.938, -1.167),
    ("MH", 2, "MH 204", "Office of the College Secretary / Administrative Staff Office", 1.938, -1.167),
    ("MH", 2, "MH 205", "", -1.185, -0.475),
    ("MH", 2, "MH 206", "", 2.647, -0.86),
    ("MH", 2, "MH 207", "College Secretary", -1.5, -0.475),
    ("MH", 2, "MH 208", "", 2.971, -0.86),
    ("MH", 2, "MH 209-211", "Office of the Associate Dean", -2.135, -0.475),
    ("MH", 2, "MH 210-214", "UP Remote Sensing Image Analysis Laboratory", 3.614, -0.86),
    ("MH", 2, "MH 213-215", "", -2.781, -0.475),
    ("MH", 2, "MH 216-218", "Training Center for Applied Geodesy and Photogrammetry", 4.263, -0.86),
    ("MH", 2, "MH 217", "", -3.096, -0.475),
    ("MH", 2, "MH 219", "", -3.434, -0.475),
    ("MH", 2, "MH 220", "", 4.912, -0.86),
    ("MH", 2, "MH 221-223", "", -4.082, -0.475),
    ("MH", 2, "MH 222", "Geodesy, Survey, Land Administration and Valuation Laboratory", 5.366, -0.86), -- 224
    ("MH", 2, "MH 225", "", -5.3, 0.224),
    ("MH", 2, "Library", "Engineering Library 1", 0.958, 0.077),
    ("MH", 2, "Male Comfort Room 2", "", 5.024, -0.887),
    ("MH", 2, "Female Comfort Room 2", "", 5.024, -0.887),
    --  Third Floor
    ("MH", 3, "MH 309-311", "", -2.154, -0.48),
    ("MH", 3, "MH 301-303", "UP ACES - DATEM Room", -0.818, -0.48),
    ("MH", 3, "MH 302-304", "Maynilad Room", 1.92, -1.17),
    ("MH", 3, "MH 305-307", "Civil Engineering Room", -1.521, -0.48),
    ("MH", 3, "MH 306-308", "", 2.637, -0.83),
    ("MH", 3, "MH 310", "Ma. Divina Cruz Casillan Room", 3.285, -0.83),
    ("MH", 3, "MH 312", "Marcello G. Casillan Room", 3.617, -0.83),
    ("MH", 3, "MH 313-315", "Epsilon Chi Alumni Inc. Room", -2.731, -0.48),
    ("MH", 3, "MH 314-316", "", 3.936, -0.83),
    ("MH", 3, "MH 317", "EE 1982 Room", -3.129, -0.48),
    ("MH", 3, "MH 318-320", "Beta Epsilon Room", 4.571, -0.83),
    ("MH", 3, "MH 319", "", -3.453, -0.48),
    ("MH", 3, "MH 321", "Januario P. ""Frondy"" Frondoso Room ", -3.781, -0.48),
    ("MH", 3, "MH 322", "UP DGE Faculty", 5.358, -0.83), -- 324
    ("MH", 3, "MH 323", "Alexan Commercial Room", -4.108, -0.48),
    ("MH", 3, "MH 325", "", -5.286, -0.312),
    ("MH", 3, "UP Engineering Theater", "", 0.939, -0.299),
    ("MH", 3, "Male Comfort Room 1", "", -4.93, -0.48),
    ("MH", 3, "Female Comfort Room 1", "", -4.598, -0.48),
    ("MH", 3, "Male Comfort Room 2", "", 5.023, -0.83),
    ("MH", 3, "Female Comfort Room 2", "", 5.023, -0.83),
    --  Fourth Floor
    ("MH", 4, "MH 401-405", "IE / OR Computing Laboratory", -0.877, -0.542),
    ("MH", 4, "MH 402-404", "Department of Industrial Engineering and Operations Research", 1.924, -1.235),
    ("MH", 4, "MH 406-408", "Applied Geodesy and Space Technology Research Laboratory", 1.988, -0.837),
    ("MH", 4, "MH 407-409", "Human Factors and Ergonomics Laboratory", -1.521, -0.542),
    ("MH", 4, "MH 410-414", "Geodetic Engineering Theater", 2.466, -0.837),
    ("MH", 4, "MH 411", "", -2.17, -0.542),
    ("MH", 4, "MH 413", "Quintin K. & Norma S. Calderon Room", -2.487, -0.542),
    ("MH", 4, "MH 415", "", -2.812, -0.542),
    ("MH", 4, "MH 416-418", "Maxima Room", 3.611, -0.837),
    ("MH", 4, "MH 417-419", "", -3.458, -0.542),
    ("MH", 4, "MH 420", "", 4.239, -0.837),
    ("MH", 4, "MH 421-423", "IDEA Laboratory", -4.095, -0.542),
    ("MH", 4, "MH 422-424", "Electrobus Consolidated Inc. Room", 4.561, -0.837),
    ("MH", 4, "MH 426", "", 5.035, -0.837),
    ("MH", 4, "MH 428", "GE Club", 5.361, -0.837),
    ("MH", 4, "Thinking Space", "", 1.022, -0.578),
    ("MH", 4, "Male Comfort Room", "", -4.905, -0.542),
    ("MH", 4, "Female Comfort Room", "", -4.581, -0.542),
    --  Fifth Floor
    ("MH", 5, "MH 500", "Procter & Gamble Philippines Audiovisual Room", 0.578, -1.075),
    ("MH", 5, "MH 501-505", "", -1.404, -0.54),
    ("MH", 5, "MH 502", "", 0.112, -0.296),
    ("MH", 5, "MH 507-509", "", -2.034, -0.54),
    ("MH", 5, "MH 511-513", "", -2.675, -0.54),
    ("MH", 5, "MH 515", "", -2.812, -0.54),
    ("MH", 5, "MH 517", "Student Disciplinary Council", -3.141, -0.54),
    ("MH", 5, "MH 519-521", "UP CAPES", -3.964, -0.54),
    ("MH", 5, "MH 523", "", -4.111, -0.54),
    ("MH", 5, "MH 525", "", -4.432, -0.54),
    ("MH", 5, "MH 527", "", -5.096, -0.51),
    ("MH", 5, "Male Comfort Room", "", -4.934, -0.51),
    ("MH", 5, "Female Comfort Room", "", -4.934, -0.51);



    -- Institute of Mathematics Main Building
    --  Ground Floor
    --  Second Floor
    --  Third Floor



    -- Institute of Mathematics Annex
    --  Ground Floor
    --  Second Floor
    --  Third Floor



    -- UP School of Labor and Industrial Relations
    --  Ground Floor
    --  Second Floor




    -- Main Library
    --  Ground Floor
    --  Second Floor
    --  Third Floor
    --  Fourth Floor