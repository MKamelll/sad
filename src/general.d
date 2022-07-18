module general;

private static int LINE = 1;
private static FILENAME = "";

void setCurrline(int num) {
    LINE = num;
}

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