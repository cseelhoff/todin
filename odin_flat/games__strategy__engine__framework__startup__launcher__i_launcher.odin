package game

I_Launcher :: struct {
	launch: proc(self: ^I_Launcher),
}

// games.strategy.engine.framework.startup.launcher.ILauncher#launch()
i_launcher_launch :: proc(self: ^I_Launcher) {
        self.launch(self)
}

