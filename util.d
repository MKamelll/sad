module util;

string generateSeparator(string ch, string line) {
    string result = "";

    for (int i = 0; i < line.length; i++) {
        result ~= ch;
    }

    return result;
}