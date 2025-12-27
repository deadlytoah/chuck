- **Prompt**: DynamoDB is complaining `comment` is a reserved keyword.
  Replace it with another word to name the attribute. Avoid choosing
  known reserved keywords in DynamoDB. Record your plan and then stop.

- **Files to modify**:
  - `lambda/dynamodb.go`
  - `lambda/types.go`
  - `src/api_service.dart`
  - `src/item.dart`
  - `src/item_detail_page.dart`
  - `technical.md`
  - `design.md`

- **Plan**:
  1. I will replace the DynamoDB attribute `comment` with `notes`.
  2. The change will apply across the entire codebase.
  3. **Backend (Go)**:
     - Modify `Item` and `UpdateItemRequest` structs in
       `lambda/types.go`.
     - Update DynamoDB update expression logic in `lambda/dynamodb.go`.
  4. **Frontend (Flutter)**:
     - Update the `Item` model in `src/item.dart` to use `notes`.
     - Change UI components in `src/item_detail_page.dart` that
       display or edit the `comment` field.
     - Adjust `src/api_service.dart` to send `notes` in update requests.
  5. **Documentation**:
     - Update `design.md` and `technical.md` to reflect the schema
       change.
