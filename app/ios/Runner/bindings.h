// NOTE: Append the lines below to ios/Classes/SrvPlugin.h

void response_free_ffi(char *response);

char *list_entries_ffi(const char *request);

char *create_entry_ffi(const char *request);

char *update_entry_ffi(const char *request);

char *delete_entry_ffi(const char *request);

char *list_streams_ffi(const char *request);

char *delete_stream_ffi(const char *request);

char *update_stream_ffi(const char *request);
