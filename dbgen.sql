PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS QRTag;
DROP TABLE IF EXISTS Building;
DROP TABLE IF EXISTS Floor;
DROP TABLE IF EXISTS IndoorLocation;

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
INSERT INTO Building VALUES
    ("UP AECH", "UP Alumni Engineering Centennial Hall", 4, TRUE, 3.0),
    ("UP ITDC", "UP Information Technology Development Center", 3, FALSE, 3.2);
INSERT INTO Floor VALUES
    ("UP AECH", 1),
    ("UP AECH", 2),
    ("UP AECH", 3),
    ("UP AECH", 4),
    ("UP ITDC", 1),
    ("UP ITDC", 2),
    ("UP ITDC", 3);
INSERT INTO IndoorLocation VALUES
    ("UP AECH", 1, "Engineering Library 2", "", 0.0, 0.0),
    ("UP AECH", 2, "Serials Section", "", -0.117, 0.137),
    ("UP AECH", 2, "The Learning Commons", "TLC", 0.126, 0.137),
    ("UP AECH", 3, "Rm 200", "Web Science Laboratory", 0.118, -0.08),
    ("UP AECH", 3, "Rm 201", "Web Science Group (WSG)", -0.102, -0.065),
    ("UP AECH", 3, "Rm 202", "ERDT Room", 0.317, 0.141),
    ("UP AECH", 3, "Rm 203", "Classroom 2 (CLR 2)", -0.282, 0.173),
    ("UP AECH", 3, "Rm 204", "Classroom 3 (CLR 3)", 0.296, 0.313),
    ("UP AECH", 3, "Rm 205", "Teaching Lab 1 (TL1)", -0.367, 0.298),
    ("UP AECH", 3, "Rm 207", "Classroom 1 (CLR 1)", -0.447, 0.132),
    ("UP AECH", 3, "Rm 210", "Teaching Lab 3 (TL3)", 0.642, 0.042),
    ("UP AECH", 3, "Rm 211", "Lecture Hall", -0.674, 0.017),
    ("UP AECH", 3, "Rm 212", "Classroom 4 (CLR 4)", 0.428, 0.262),
    ("UP AECH", 3, "Rm 214", "Teaching Lab 2 (TL2)", 0.687, 0.173),
    ("UP AECH", 3, "Rm 215", "Seminar Room", -0.518, 0.25),
    ("UP AECH", 4, "Administration Office", "", 0.0, 0.0),
    ("UP ITDC", 1, "Rm 101", "", 0.0, 0.0),
    ("UP ITDC", 2, "Conference Room", "", 0.0, 0.0),
    ("UP ITDC", 3, "Networks and Infrastructure", "", 0.0, 0.0);

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