# Civic Changes to ms-365-mcp-server

This fork contains modifications to support file attachment and upload functionality in the Microsoft Graph API.

## Changes Made

### 1. Added `contentBytes` to Priority Properties

**File:** `bin/modules/simplified-openapi.mjs`
**Line:** 244

**Problem:**
The OpenAPI schema simplification process was removing the `contentBytes` property from attachment schemas when they had more than 25 properties. This is because `contentBytes` was not in the priority properties list, causing all file upload and attachment operations to fail.

**Solution:**
Added `contentBytes` to the `priorityProperties` array in the `reduceProperties()` function. This ensures that when schemas are simplified, the critical `contentBytes` property is preserved.

```javascript
const priorityProperties = [
  'id',
  'name',
  // ... other properties
  'content',
  'contentBytes', // Added for file upload/attachment support
  'body',
  // ... other properties
];
```

**Impact:**
- ✅ `add-mail-attachment` - Now works correctly
- ✅ `send-mail` with attachments - Now works correctly
- ✅ OneDrive file uploads - Should now work correctly (related to issue #56)

## Testing

To test the fix:

1. Regenerate the OpenAPI schemas:
   ```bash
   npm install
   npm run bin/generate-graph-client.mjs
   ```

2. Build and run the server:
   ```bash
   npm run build
   npm start
   ```

3. Test add-mail-attachment with a sample file:
   ```json
   {
     "messageId": "YOUR_MESSAGE_ID",
     "body": {
       "@odata.type": "#microsoft.graph.fileAttachment",
       "name": "test.txt",
       "contentBytes": "SGVsbG8gV29ybGQh"
     }
   }
   ```

## Known Limitations

### `@odata.type` Removal

The `removeODataTypeRecursively()` function (line 65) globally removes all `@odata.type` properties from schemas. While this simplifies the schemas, it may cause issues with polymorphic types like attachments where `@odata.type` is semantically important.

**Current Status:** Left as-is to avoid unintended side effects. The Microsoft Graph API may handle this automatically, or clients can include it in their requests even if not in the schema.

**Future Consideration:** Could conditionally preserve `@odata.type` for specific schemas (e.g., attachment types) if needed.

## Contributing Back Upstream

This fix should be contributed back to the upstream Softeria/ms-365-mcp-server repository once tested and validated in production.

**Related Issues:**
- [#56](https://github.com/Softeria/ms-365-mcp-server/issues/56) - Support for OneDrive File Upload
- File attachments not working (to be reported)

## Maintenance

To keep this fork up to date with upstream:

```bash
# Add upstream remote (one time)
git remote add upstream https://github.com/Softeria/ms-365-mcp-server.git

# Fetch and merge upstream changes
git fetch upstream
git merge upstream/main

# Verify our changes are preserved
git diff HEAD bin/modules/simplified-openapi.mjs
```
