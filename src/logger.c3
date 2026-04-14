module logger;

import std::core::string::ansi;
import std::io;
import std::time::datetime;

fn String get_timestamp() @private {
    TzDateTime time = datetime::now().to_local();
    String time_format = datetime::tformat(TIMEONLY, time);
    return string::tformat("[%s%s%s]", Ansi.GREEN, time_format, Ansi.RESET);
}

macro warn(String fmt, args...) => print("WARN", Ansi.YELLOW, fmt, ...args);
macro info(String fmt, args...) => print("INFO", Ansi.BLUE, fmt, ...args);
macro error(String fmt, args...) => print("ERROR", Ansi.RED, fmt, ...args);

fn void print(String type, String color, String fmt, args...) @private {
    io::printfn("%s [%s%s%s] %s", get_timestamp(), color, type, Ansi.RESET, string::tformat(fmt, ...args));
}
