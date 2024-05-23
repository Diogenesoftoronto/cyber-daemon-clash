# Cyber Daemon Clash

To load and run Cyber Daemon Clash powered by the Trail game project in Common Lisp, follow these steps:

## Loading and Running the Project:

1. **Install Quicklisp**: If you haven't already installed Quicklisp, follow the instructions on the [Quicklisp website](https://www.quicklisp.org/beta/#installation).

2. **Install Trial and Dependencies**: Open your Lisp REPL and run:
   ```lisp
   (ql:quickload '(:trial :trial-glfw :trial-png))
   ```

3. **Load Your Project**: In the same REPL session, navigate to your project directory and load the system:
   ```lisp
   (load "cyber-daemon-clash.asd")
   (asdf:load-system :cyber-daemon-clash)
   ```

4. **Launch the Game**: Finally, run the `launch` function to start your game:
   ```lisp
   (org.cyber-daemon-clash:launch)
   ```
At some point there will be a setup script so that you do not have to do this manually much like [kandria](https://www.github.com/shirakumo/kandria).
