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
    ("Building::2::PointA", 0.0, 0.0);

INSERT INTO Building VALUES
    ("Building", "Sample Hall", 3, FALSE, 3.0, 1, 1, 0);
INSERT INTO Floor VALUES
    ("Building", 1),
    ("Building", 2),
    ("Building", 3);
INSERT INTO Staircase VALUES
    ("Building", 0.0, 0.25),
    ("Building", 0.25, 0.0);
INSERT INTO IndoorLocation VALUES
    --  Ground Floor
    ("Building", 1, "Room 100", "Sample Room 1", 1.0, 1.0),
    --  Second Floor
    ("Building", 2, "Room 200", "Sample Room 2", 1.0, 1.0),
    --  Third Floor
    ("Building", 3, "Room 300", "Sample Room 3", 1.0, 1.0);