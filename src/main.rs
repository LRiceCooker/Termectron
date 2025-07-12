fn main() {
    println!("Hello from MyTerminalApp!");
    println!("This is a simple terminal application running inside Alacritty.");
    println!("Press Enter to exit...");
    let mut input = String::new();
    std::io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    // Your actual terminal application logic goes here
    // For now, this is just a demo
}
