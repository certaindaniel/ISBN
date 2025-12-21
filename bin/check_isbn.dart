import 'package:isbn_book_manager/services/isbn_service.dart';
import 'package:isbn_book_manager/utils/app_logger.dart';

void main() {
  AppLogger.info("0140328726 -> ${IsbnService.isValidIsbn('0140328726')}");
  AppLogger.info("0140328721 -> ${IsbnService.isValidIsbn('0140328721')}");
  AppLogger.info("014032872X -> ${IsbnService.isValidIsbn('014032872X')}");
}
