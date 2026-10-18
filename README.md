# TodoCat

TodoCat is a customizable to-do list that turns productivity into a visual experience. Your character's running speed reflects your task completion progress, helping you stay motivated as you work through your daily goals.

## Features

- **Task management:** Create, edit, delete, and complete tasks.
- **Progress-based animation:** The character's running speed changes according to the proportion of completed tasks.
- **Reverse speed mode:** Optionally make the character slow down as more tasks are completed.
- **Customizable characters:** Choose from different characters and animation styles, such as cats, pixel-art characters, and other runners.
- **Local storage:** Keep tasks on your device.
- **Account and cloud sync:** Sign in with Google or email to store and synchronize tasks across devices, if cloud sync is implemented.

## How It Works

TodoCat calculates progress using the number of completed tasks divided by the total number of tasks.

```text
Completion percentage = (Completed tasks / Total tasks) * 100
```

For example, completing 6 out of 10 tasks results in 60% progress. In normal mode, the character runs at a speed corresponding to that progress. In reverse mode, the speed is inverted.

## Project Goals

- Make task management engaging and motivating.
- Support customizable characters and animations.
- Give users control over how their data is stored.

## Development Status

TodoCat is a project in development. Features described in this README may be planned rather than implemented.

## Contributing

Ideas, bug reports, and contributions are welcome. If you would like to contribute, open an issue to discuss a proposed change before submitting a pull request.

## License

A license has not yet been selected. Until one is added, all rights remain with the project owner.
