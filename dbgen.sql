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
    ("UP AECH::1::A", 0.0, 0.0),
    ("UP AECH::1::B", 0.0, 0.0),
    ("UP AECH::1::C", 0.0, 0.0),
    ("UP AECH::2::A", 1.0, 1.0),
    ("UP AECH::3::A", 0.0, 0.0),
    ("UP AECH::4::A", 0.0, 0.0),
    ("UP ITDC::1::A", 0.0, 0.0),
    ("UP ITDC::2::A", 0.0, 0.0),
    ("UP ITDC::3::A", 0.0, 0.0);
    ("Melchor Hall::1::A", 0.0, 0.0),
    ("Melchor Hall::2::A", 0.0, 0.0),
    ("Melchor Hall::3::A", 0.0, 0.0);
INSERT INTO Building VALUES
    ("UP AECH", "UP Alumni Engineers Centennial Hall", 4, TRUE, 3.0, 1.885, 1, 90),
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
    ("UP AECH", 1, "Engineering Library 2", "", 0.0, 0.0),
    ("UP AECH", 2, "Serials Section", "", -0.378, -0.056),
    ("UP AECH", 2, "The Learning Commons", "TLC", 0.277, 0.195),
    ("UP AECH", 3, "Rm 200", "Web Science Laboratory", 0.046, 0.018),
    ("UP AECH", 3, "Rm 201", "Web Science Group (WSG)", -0.031, 0.018),
    ("UP AECH", 3, "Rm 202", "ERDT Room", 0.225, 0.2),
    ("UP AECH", 3, "Rm 203", "Classroom 2 (CLR 2)", -0.207, 0.2),
    ("UP AECH", 3, "Rm 204", "Classroom 3 (CLR 3)", 0.234, 0.35),
    ("UP AECH", 3, "Rm 205", "Teaching Lab 1 (TL1)", -0.215, 0.266),
    ("UP AECH", 3, "Rm 207", "Classroom 1 (CLR 1)", -0.515, 0.032),
    ("UP AECH", 3, "Rm 210", "Teaching Lab 3 (TL3)", 0.477, 0.045),
    ("UP AECH", 3, "Rm 211", "Lecture Hall", -0.51, -0.128),
    ("UP AECH", 3, "Rm 212", "Classroom 4 (CLR 4)", 0.482, 0.2),
    ("UP AECH", 3, "Rm 214", "Teaching Lab 2 (TL2)", 0.556, 0.262),
    ("UP AECH", 3, "Rm 215", "Seminar Room", -0.614, 0.244),
    ("UP AECH", 4, "Rm 300", "Administration Office", 0.0, 0.0),

    -- UP Information Technology Development Center
    ("UP ITDC", 1, "Rm 101", "", 0.0, 0.0),
    ("UP ITDC", 2, "Conference Room", "", 0.0, 0.0),
    ("UP ITDC", 3, "Networks and Infrastructure", "", 0.0, 0.0),

    -- College of Engineering
    ("Melchor Hall", 1, "Rm 100", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 101", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 102", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 104-106", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 105-111", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 108-110", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 112-114", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 116", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 118", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 117", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 119-121", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 120", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 113-115", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Rm 123", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Male Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Female Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 1, "Male Comfort Room 2", "", 0.0, 0.0)
    ("Melchor Hall", 2, "Rm 201-203", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 202", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 204", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 205", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 206", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 207", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 208", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 209-211", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 210-214", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 213-215", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 216-218", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 217", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 219", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 220", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 221-223", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 222", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Rm 225", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Library", "Engineering Library 1", 0.0, 0.0),
    ("Melchor Hall", 2, "Male Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Female Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Male Comfort Room 2", "", 0.0, 0.0),
    ("Melchor Hall", 2, "Female Comfort Room 2", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 325", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 323", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 321", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 319", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 317", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 313-315", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 309-311", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 305-307", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 301-303", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 302-304", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 306-308", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 310", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 312", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 314-316", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 318-320", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Rm 322", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Male Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Female Comfort Room 1", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Male Comfort Room 2", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Female Comfort Room 2", "", 0.0, 0.0),
    ("Melchor Hall", 3, "Engineering Theater", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 421-423", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 417-419", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 415", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 413", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 411", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 407-409", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 405", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 401-403", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 406-408", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 410-414", "Geodetic Engineering Theater", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 416-418", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 420", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 422-424", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 426", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 428", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Rm 402-404", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Male Comfort Room", "", 0.0, 0.0),
    ("Melchor Hall", 4, "Female Comfort Room", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 527", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 525", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 523", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 519-521", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 517", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 515", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 511-513", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 507-509", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 501-505", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 502", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Rm 500", "Procter & Gamble Theater", 0.0, 0.0),
    ("Melchor Hall", 5, "Male Comfort Room", "", 0.0, 0.0),
    ("Melchor Hall", 5, "Female Comfort Room", "", 0.0, 0.0);

    -- Main Library

-- Notes:
--  QRTag is for initialization and localization. URL attribute stores strings of the form
--      BuildingAlias::FloorLevel ->
--        BuildingAlias used to determine building
--        BuildingAlias::FloorLevel used to determine Floor
--  Building information important for altimeter updates
--  Floor rows store paths to floor plans for plane retexturing
--  IndoorLocation entries show up in UI; relocate pin marker upon selection
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Additional useful info:
--  - For Building, user marker rotation offset
--  - Don't forget to scale maps/user or both (not necessarily same time)