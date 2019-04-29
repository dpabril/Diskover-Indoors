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
    ("Melchor Hall::3::A", 0.0, 0.0);

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
    ("UP AECH::4::CVMIG", -1.587, 0.245),

INSERT INTO Building VALUES
    ("UP AECH", "UP Alumni Engineers Centennial Hall", 4, TRUE, 3.0, 7.995, 4.086, 90),
    ("UP ITDC", "UP Information Technology Development Center", 3, FALSE, 3.2, 1, 1, 0),
    ("Melchor Hall", "Melchor Hall", 5, FALSE, 4.0, 2.834, 1.411, 0);
INSERT INTO Floor VALUES
    ("UP AECH", 1),
    ("UP AECH", 2),
    ("UP AECH", 3),
    ("UP AECH", 4),
    ("UP ITDC", 1),
    ("UP ITDC", 2),
    ("UP ITDC", 3),
    ("Melchor Hall", 1),
    ("Melchor Hall", 2),
    ("Melchor Hall", 3),
    ("Melchor Hall", 4),
    ("Melchor Hall", 5);
INSERT INTO Staircase VALUES
    ("UP AECH", 0.281, -0.124),
    ("UP AECH", -0.27, -0.124),
    ("UP ITDC", 0.281, -0.124),
    ("UP ITDC", -0.27, -0.124),
    ("Melchor Hall", 0.281, -0.124),
    ("Melchor Hall", -0.27, -0.124);
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
    ("UP AECH", 3, "Rm 211", "Lecture Hall", -2.136, -0.486),
    ("UP AECH", 3, "Rm 212", "Classroom 4 (CLR 4)", 2.082, 0.823),
    ("UP AECH", 3, "Rm 214", "Teaching Lab 2 (TL2)", 2.393, 1.111),
    ("UP AECH", 3, "Rm 215", "Seminar Room", -2.604, 1.066),
    --  Third Floor
    ("UP AECH", 4, "Rm 300", "Administration Office", 0.038, 0.172),



    -- UP Information Technology Development Center
    --  Ground Floor
    ("UP ITDC", 1, "Rm 101", "", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 103", "Audio Visual Room", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 104", "Office of the Former President", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 105", "Property Room", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 106", "", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 108", "", 0.0, 0.0),

    --  Second Floor
    ("UP ITDC", 2, "Rm 201", "Office of the Director Conference Room", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 203", "Trainers Office", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 204", "Laboratory 3", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 205", "Administration Office", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 206", "Server Room", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 207", "", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 208", "", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 210", "", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 211", "Conference Room", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 212", "Laboratory 5", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 213", "", 0.0, 0.0),
    ("UP ITDC", 2, "Rm 214", "", 0.0, 0.0),
    --  Third Floor
    ("UP ITDC", 3, "Networks and Infrastructure", "", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 301", "Software Engg and Information Systems Group", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 303", "", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 304", "", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 304-B", "Office of the Director", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 305", "OVPD Project Managament Office", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 306", "Office of the Deputy Director", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 307", "", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 308", "Tech Support", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 308-B", "Communications", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 309", "EITSC Computer Laboratory", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 310", "", 0.0, 0.0),
    ("UP ITDC", 3, "Rm 312", "Infra and Tech Support Group", 0.0, 0.0),



    -- College of Engineering
    --  Ground Floor
    ("Melchor Hall", 1, "MH 100", "DCE Faculty Office", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 101", "", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 102", "CoMSLab (Admin)", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 104-106", "Rosario S. Calderon Room", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 105-111", "Faculty Lounge", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 108-110", "Environmental Systems Applications of Geomatics Engineering Research Laboratory", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 112-114", "", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 113-115", "Property Office", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 116", "", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 118", "", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 117", "NECFI", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 119-121", "", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 120", "", 0.0, 0.0), -- 122
    ("Melchor Hall", 1, "MH 122", "DGE Instrument Room", 0.0, 0.0),
    ("Melchor Hall", 1, "MH 123", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Male Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Female Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Male Comfort Room 2", "", 0.0, 0.0),
    --  Second Floor
    ("Melchor Hall", 2, "MH 201-203", "DOST-ERDT Project Office", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 202", "Dean's Office", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 204", "Office of the College Secretary / Administrative Staff Office", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 205", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 206", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 207", "College Secretary", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 208", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 209", "Angel F. Caringal Computer Room", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 211", "Office of the Associate Dean", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 210-214", "UP Remote Sensing Image Analysis Laboratory", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 213-215", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 216-218", "Training Center for Applied Geodesy and Photogrammetry", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 217", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 219", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 220", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 221-223", "", 0.0, 0.0),
    ("Melchor Hall", 2, "MH 222", "Geodesy, Survey, Land Administration and Valuation Laboratory", 0.0, 0.0), -- 224
    ("Melchor Hall", 2, "MH 225", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Library", "Engineering Library 1", 0.0, 0.0),
    ("Melchor Hall", 2, "Male Comfort Room 2", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Female Comfort Room 2", "", 0.0, 0.0),
    --  Third Floor
    ("Melchor Hall", 3, "MH 309-311", "", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 301-303", "UP ACES - DATEM Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 302-304", "Maynilad Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 305-307", "Civil Engineering Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 306-308", "", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 310", "Ma. Divina Cruz Casillan Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 312", "Marcello G. Casillan Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 313-315", "Epsilon Chi Alumni Inc. Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 314-316", "", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 317", "EE 1982 Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 318-320", "Beta Epsilon Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 319", "", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 321", "Januario P. ""Frondy"" Frondoso Room ", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 322", "UP DGE Faculty", 0.0, 0.0), -- 324
    ("Melchor Hall", 3, "MH 323", "Alexan Commercial Room", 0.0, 0.0),
    ("Melchor Hall", 3, "MH 325", "", 0.0, 0.0),
    ("Melchor Hall", 3, "UP Engineering Theater", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Male Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Female Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Male Comfort Room 2", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Female Comfort Room 2", "", 0.0, 0.0),
    --  Fourth Floor
    ("Melchor Hall", 4, "MH 401-405", "IE / OR Computing Laboratory", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 402-404", "Department of Industrial Engineering and Operations Research", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 406-408", "Applied Geodesy and Space Technology Research Laboratory", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 407-409", "Human Factors and Ergonomics Laboratory", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 410-414", "Geodetic Engineering Theater", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 411", "", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 413", "Quintin K. & NoMHa S. Calderon Room", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 415", "", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 416-418", "Maxima Room", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 417-419", "", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 420", "", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 421-423", "IDEA Laboratory", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 422-424", "Electrobus Consolidated Inc. Room", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 426", "", 0.0, 0.0),
    ("Melchor Hall", 4, "MH 428", "GE Club", 0.0, 0.0),
    ("Melchor Hall", 4, "Male Comfort Room", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Female Comfort Room", "", 0.0, 0.0),
    --  Fifth Floor
    ("Melchor Hall", 5, "MH 500", "Procter & Gamble Philippines Audiovisual Room", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 501-505", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 502", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 507-509", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 511-513", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 515", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 517", "Student Disciplinary Council", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 519-521", "UP CAPES", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 523", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 525", "", 0.0, 0.0),
    ("Melchor Hall", 5, "MH 527", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Male Comfort Room", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Female Comfort Room", "", 0.0, 0.0);



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