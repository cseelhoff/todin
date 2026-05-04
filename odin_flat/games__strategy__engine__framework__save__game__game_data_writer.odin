package game

Game_Data_Writer :: struct {}

// Java:
//   private static void writeToOutputStream(GameData, OutputStream, DelegateExecutionManager)
//     try {
//       if (!dem.blockDelegateExecution(6000) && !dem.blockDelegateExecution(6000)) {
//         log.error(errorMessage + " could not lock delegate execution");
//         return;
//       }
//     } catch (InterruptedException e) { Thread.currentThread().interrupt(); return; }
//     try { GameDataManager.saveGame(out, gameData); }
//     finally { dem.resumeDelegateExecution(); }
//
// Odin port: no checked exceptions; block_delegate_execution never
// throws InterruptedException so the catch arm is unreachable. The
// retry is preserved as in Java (call twice, bail if both fail).
game_data_writer_write_to_output_stream :: proc(
	game_data: ^Game_Data,
	out: ^Output_Stream,
	delegate_execution_manager: ^Delegate_Execution_Manager,
) {
	if !delegate_execution_manager_block_delegate_execution(delegate_execution_manager, 6000) &&
	   !delegate_execution_manager_block_delegate_execution(delegate_execution_manager, 6000) {
		// log.error("Error saving game..  could not lock delegate execution")
		return
	}
	defer delegate_execution_manager_resume_delegate_execution(delegate_execution_manager)
	game_data_manager_save_game(out, game_data)
}

// Java lambda inside writeToBytes:
//   outputStream -> writeToOutputStream(gameData, outputStream, dem)
// Captured args (gameData, dem) come first; the lambda's own
// OutputStream argument is last. The Java return type is void; the
// surrounding ThrowingConsumer surfaces IOException, which our
// shimmed write_to_output_stream never raises in the harness.
game_data_writer_lambda_write_to_bytes_0 :: proc(
	game_data: ^Game_Data,
	delegate_execution_manager: ^Delegate_Execution_Manager,
	output_stream: ^Output_Stream,
) {
	game_data_writer_write_to_output_stream(game_data, output_stream, delegate_execution_manager)
}

// Java:
//   public static void writeToFile(GameData gameData,
//                                  DelegateExecutionManager dem,
//                                  Path file) {
//     try (OutputStream fout = Files.newOutputStream(file)) {
//       writeToOutputStream(gameData, fout, dem);
//     } catch (IOException e) {
//       log.error("Failed to save game to file: " + file.toAbsolutePath(), e);
//     }
//   }
//
// Odin port: the JDK shim's files_new_output_stream returns an
// in-memory Output_Stream and never raises I/O errors in the
// harness, so the catch arm is unreachable. The try-with-resources
// close is mirrored via `defer output_stream_close`.
game_data_writer_write_to_file :: proc(
	game_data: ^Game_Data,
	delegate_execution_manager: ^Delegate_Execution_Manager,
	file: Path,
) {
	fout := files_new_output_stream(file)
	defer output_stream_close(fout)
	game_data_writer_write_to_output_stream(game_data, fout, delegate_execution_manager)
}

