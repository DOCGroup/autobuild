PASS = 0
FAIL = 1
SKIP = 3

NEW_FORMAT = 1
OLD_FORMAT = 0

ACE_TEST = 0
TAO_TEST = 1


def ComputePercentage(numerator, denominator):
    perc = 0.0
    try:
        perc = (float(numerator) / float(denominator)) * 100.0
    except ZeroDivisionError:
        pass
    # print("divide by zero attempt")
    return perc


def txt2DbFname(txtFname):
    splits = txtFname.split("/")
    length = len(splits)
    dbFname = splits[length - 2] + "_" + splits[length - 1]
    dbFname = dbFname.replace(".txt", ".db")
    return dbFname
