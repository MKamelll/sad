module general;

private static int LINE = 0;
private static FILENAME = "";

void incCurrLine() {
    LINE++;
}

int getCurrLine() {
    return LINE;
}

void setFileName(string name) {
    FILENAME = name;
}

string getFileName() {
    return FILENAME;
}