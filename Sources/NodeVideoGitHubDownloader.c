/*
 * NodeVideoGitHubDownloader.c
 * Native dylib port of the supplied 2.js.
 *
 * Target contract copied from 2.js:
 *   UnityFramework
 *   DownloadODR.MoveNext          RVA 0x2E13604
 *   DownloadAppAssetsDialog.Close RVA 0x2E12C94
 *   AbstractProgressBar.set_title RVA 0x5B39F30
 *   AbstractProgressBar.set_value RVA 0x5B3A674
 *
 * This source intentionally avoids SDK headers so it can be cross-linked as a
 * Mach-O dylib in the current Linux environment. Foundation/ObjC are called
 * through the Objective-C runtime already present in an iOS app process.
 */

/* ---------- minimal Darwin / Objective-C declarations ---------- */
typedef unsigned long usize_t;
typedef long isize_t;
typedef long intptr_t;
typedef unsigned long uintptr_t;
typedef long long int64_t;
typedef int int32_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

typedef void *id;
typedef void *Class;
typedef void *SEL;
typedef void *Protocol;
typedef signed char ObjCBool;

struct mach_header;

typedef struct {
    const char *dli_fname;
    void *dli_fbase;
    const char *dli_sname;
    void *dli_saddr;
} Dl_info;

extern Class objc_getClass(const char *name);
extern SEL sel_registerName(const char *name);
extern void objc_msgSend(void);
extern Class objc_allocateClassPair(Class superclass, const char *name, usize_t extraBytes);
extern void objc_registerClassPair(Class cls);
extern ObjCBool class_addMethod(Class cls, SEL name, void *imp, const char *types);
extern ObjCBool class_addProtocol(Class cls, Protocol *protocol);
extern Protocol *objc_getProtocol(const char *name);

extern void _dyld_register_func_for_add_image(void (*func)(const struct mach_header *, intptr_t));
extern int dladdr(const void *addr, Dl_info *info);
extern void *dlsym(void *handle, const char *symbol);

extern void *malloc(usize_t size);
extern void free(void *ptr);
extern void *memcpy(void *dst, const void *src, usize_t n);
extern usize_t strlen(const char *s);
extern int strcmp(const char *a, const char *b);
extern int snprintf(char *dst, usize_t cap, const char *fmt, ...);
extern int printf(const char *fmt, ...);
extern int getpid(void);

typedef void *dispatch_queue_t;
extern dispatch_queue_t dispatch_get_main_queue(void);
extern void dispatch_async_f(dispatch_queue_t queue, void *context, void (*work)(void *));

#define RTLD_DEFAULT ((void *)(intptr_t)-2)
#define NULLPTR ((void *)0)

#define MODULE_NAME "UnityFramework"
#define GH_BASE "https://github.com/Nic041018/NodeVideo-AI-Models/releases/download/v1.0/"

#define RVA_MOVE_NEXT          ((uintptr_t)0x2E13604ULL)
#define RVA_CLOSE              ((uintptr_t)0x2E12C94ULL)
#define RVA_PROGRESS_SET_TITLE ((uintptr_t)0x5B39F30ULL)
#define RVA_PROGRESS_SET_VALUE ((uintptr_t)0x5B3A674ULL)

#define PATH_CAP 4096
#define RESOURCE_CAP 2049
#define URL_CAP 8192

/* ---------- typed objc_msgSend helpers ---------- */
static SEL S(const char *name) { return sel_registerName(name); }

static id MsgId0(id obj, const char *sel) {
    return ((id (*)(id, SEL))objc_msgSend)(obj, S(sel));
}
static id MsgId1Id(id obj, const char *sel, id a1) {
    return ((id (*)(id, SEL, id))objc_msgSend)(obj, S(sel), a1);
}
static id MsgId2UL(id obj, const char *sel, unsigned long a1, unsigned long a2) {
    return ((id (*)(id, SEL, unsigned long, unsigned long))objc_msgSend)(obj, S(sel), a1, a2);
}
static id MsgId3Id(id obj, const char *sel, id a1, id a2, id a3) {
    return ((id (*)(id, SEL, id, id, id))objc_msgSend)(obj, S(sel), a1, a2, a3);
}
static const char *MsgCStr0(id obj, const char *sel) {
    return ((const char *(*)(id, SEL))objc_msgSend)(obj, S(sel));
}
static unsigned long MsgUL0(id obj, const char *sel) {
    return ((unsigned long (*)(id, SEL))objc_msgSend)(obj, S(sel));
}
static void MsgVoid0(id obj, const char *sel) {
    ((void (*)(id, SEL))objc_msgSend)(obj, S(sel));
}
static ObjCBool MsgBool1Id(id obj, const char *sel, id a1) {
    return ((ObjCBool (*)(id, SEL, id))objc_msgSend)(obj, S(sel), a1);
}
static ObjCBool MsgBool2IdErr(id obj, const char *sel, id a1, id *err) {
    return ((ObjCBool (*)(id, SEL, id, id *))objc_msgSend)(obj, S(sel), a1, err);
}
static ObjCBool MsgBool2IdIdErr(id obj, const char *sel, id a1, id a2, id *err) {
    return ((ObjCBool (*)(id, SEL, id, id, id *))objc_msgSend)(obj, S(sel), a1, a2, err);
}
static ObjCBool MsgBool4CreateDir(id obj, id path, ObjCBool intermediate, id attrs, id *err) {
    return ((ObjCBool (*)(id, SEL, id, ObjCBool, id, id *))objc_msgSend)(
        obj, S("createDirectoryAtPath:withIntermediateDirectories:attributes:error:"),
        path, intermediate, attrs, err);
}
static id MsgId1CStr(id obj, const char *sel, const char *s) {
    return ((id (*)(id, SEL, const char *))objc_msgSend)(obj, S(sel), s);
}

static void RetainObj(id obj) { if (obj) MsgId0(obj, "retain"); }
static void ReleaseObj(id obj) { if (obj) MsgVoid0(obj, "release"); }

static id ClassObj(const char *name) { return (id)objc_getClass(name); }
static id MakeNSString(const char *text) {
    if (!text) return NULLPTR;
    id cls = ClassObj("NSString");
    return cls ? MsgId1CStr(cls, "stringWithUTF8String:", text) : NULLPTR;
}

/* ---------- model table ---------- */
typedef struct {
    const char *name;
    int64_t size;
} ModelFile;

static const ModelFile kDepthFiles[] = {
    { "depthgenerator_model_dynamic.sentis", 98952556LL }
};

static const ModelFile kSam2Files[] = {
    { "image_encoder_v1.sentis", 165736548LL },
    { "mask_decoder_v1.sentis", 16808604LL },
    { "memory_attention_v1.sentis", 25848240LL },
    { "memory_encoder_v1.sentis", 5817820LL },
    { "mlp_v1.sentis", 790780LL },
    { "prompt_encoder_v1.sentis", 1103040LL }
};

static const ModelFile kFaceFiles[] = {
    { "face_detection_256_v1.sentis", 729324LL },
    { "face_landmarks_detector_v1.sentis", 4885724LL },
    { "iris_landmark_v1.sentis", 5861764LL }
};

/* ---------- target function pointers ---------- */
typedef void *(*Il2CppStringNewFn)(const char *text);
typedef void (*CloseFn)(void *dialog, void *methodInfo);
typedef void (*ProgressValueFn)(void *bar, float value, void *methodInfo);
typedef void (*ProgressTitleFn)(void *bar, void *title, void *methodInfo);
typedef int (*MoveNextFn)(void *sm, void *methodInfo);
typedef void (*MSHookFunctionFn)(void *symbol, void *replace, void **result);
typedef int (*DobbyHookFn)(void *address, void *replace, void **origin);

static Il2CppStringNewFn gIl2CppStringNew = NULLPTR;
static CloseFn gClose = NULLPTR;
static ProgressValueFn gProgressValue = NULLPTR;
static ProgressTitleFn gProgressTitle = NULLPTR;
static MoveNextFn gOriginalMoveNext = NULLPTR;
static MSHookFunctionFn gMSHookFunction = NULLPTR;
static DobbyHookFn gDobbyHook = NULLPTR;

static id gSession = NULLPTR;
static id gDelegate = NULLPTR;
static int gHookInstalled = 0;
static int gInstallScheduled = 0;
static int gEnabled = 1;

/* ---------- state ---------- */
typedef enum {
    JOB_DOWNLOADING = 0,
    JOB_DONE = 1,
    JOB_FAILED = 2
} JobStatus;

typedef struct Job {
    void *sm;
    void *dialog;
    char resource[RESOURCE_CAP];
    char dir[PATH_CAP];
    const ModelFile *files;
    int fileCount;
    int index;
    int64_t totalBytes;
    int64_t completedBytes;
    float progress;
    int lastPercent;
    id currentTask;
    JobStatus status;
    char *error;
    int finalized;
    struct Job *next;
} Job;

typedef struct TaskContext {
    unsigned long taskId;
    Job *job;
    const ModelFile *file;
    struct TaskContext *next;
} TaskContext;

static Job *gJobs = NULLPTR;
static TaskContext *gTaskContexts = NULLPTR;

static usize_t CopyString(char *dst, usize_t cap, const char *src) {
    usize_t n = 0;
    if (!dst || cap == 0) return 0;
    if (!src) { dst[0] = '\0'; return 0; }
    while (src[n] && n + 1 < cap) { dst[n] = src[n]; n++; }
    dst[n] = '\0';
    return n;
}

static char *DupString(const char *src) {
    if (!src) return NULLPTR;
    usize_t n = strlen(src);
    char *p = (char *)malloc(n + 1);
    if (!p) return NULLPTR;
    memcpy(p, src, n + 1);
    return p;
}

static int AsciiLower(int c) {
    return (c >= 'A' && c <= 'Z') ? (c + ('a' - 'A')) : c;
}

static int ContainsHDCaseInsensitive(const char *s) {
    if (!s) return 0;
    while (s[0] && s[1]) {
        if (AsciiLower((unsigned char)s[0]) == 'h' &&
            AsciiLower((unsigned char)s[1]) == 'd') return 1;
        s++;
    }
    return 0;
}

static const char *LastPathComponent(const char *path) {
    const char *last = path;
    if (!path) return NULLPTR;
    for (const char *p = path; *p; ++p) if (*p == '/') last = p + 1;
    return last;
}

static Job *FindJob(void *sm) {
    for (Job *j = gJobs; j; j = j->next) if (j->sm == sm) return j;
    return NULLPTR;
}

static void AddJob(Job *job) {
    job->next = gJobs;
    gJobs = job;
}

static void AddTaskContext(unsigned long taskId, Job *job, const ModelFile *file) {
    TaskContext *ctx = (TaskContext *)malloc(sizeof(TaskContext));
    if (!ctx) return;
    ctx->taskId = taskId;
    ctx->job = job;
    ctx->file = file;
    ctx->next = gTaskContexts;
    gTaskContexts = ctx;
}

static TaskContext *FindTaskContext(unsigned long taskId) {
    for (TaskContext *c = gTaskContexts; c; c = c->next) if (c->taskId == taskId) return c;
    return NULLPTR;
}

static void RemoveTaskContext(unsigned long taskId) {
    TaskContext **pp = &gTaskContexts;
    while (*pp) {
        if ((*pp)->taskId == taskId) {
            TaskContext *dead = *pp;
            *pp = dead->next;
            free(dead);
            return;
        }
        pp = &(*pp)->next;
    }
}

static void RemoveContextsForJob(Job *job) {
    TaskContext **pp = &gTaskContexts;
    while (*pp) {
        if ((*pp)->job == job) {
            TaskContext *dead = *pp;
            *pp = dead->next;
            free(dead);
        } else {
            pp = &(*pp)->next;
        }
    }
}

static void RemoveJob(void *sm) {
    Job **pp = &gJobs;
    while (*pp) {
        if ((*pp)->sm == sm) {
            Job *dead = *pp;
            *pp = dead->next;
            RemoveContextsForJob(dead);
            if (dead->currentTask) ReleaseObj(dead->currentTask);
            if (dead->error) free(dead->error);
            free(dead);
            return;
        }
        pp = &(*pp)->next;
    }
}

/* ---------- IL2CPP string ---------- */
static int ReadIl2CppStringAscii(void *ptr, char *out, usize_t cap) {
    if (!out || cap == 0) return 0;
    out[0] = '\0';
    if (!ptr) return 0;

    int32_t len = *(int32_t *)((uintptr_t)ptr + 0x10);
    if (len < 0 || len > 2048) return 0;
    if ((usize_t)len + 1 > cap) return 0;

    const uint16_t *chars = (const uint16_t *)((uintptr_t)ptr + 0x14);
    for (int32_t i = 0; i < len; i++) {
        uint16_t ch = chars[i];
        out[i] = (ch <= 0x7f) ? (char)ch : '?';
    }
    out[len] = '\0';
    return 1;
}

/* ---------- Foundation helpers ---------- */
static id FileManager(void) {
    id cls = ClassObj("NSFileManager");
    return cls ? MsgId0(cls, "defaultManager") : NULLPTR;
}

static int GetDocumentsPath(char *out, usize_t cap) {
    id fm = FileManager();
    if (!fm) return 0;
    id urls = MsgId2UL(fm, "URLsForDirectory:inDomains:", 9UL, 1UL);
    if (!urls) return 0;
    id url = MsgId0(urls, "lastObject");
    if (!url) return 0;
    id path = MsgId0(url, "path");
    if (!path) return 0;
    const char *utf8 = MsgCStr0(path, "UTF8String");
    if (!utf8) return 0;
    CopyString(out, cap, utf8);
    return out[0] != '\0';
}

static void MkdirPath(const char *path) {
    id fm = FileManager();
    id p = MakeNSString(path);
    if (fm && p) MsgBool4CreateDir(fm, p, 1, NULLPTR, NULLPTR);
}

static int FileExists(const char *path) {
    id fm = FileManager();
    id p = MakeNSString(path);
    if (!fm || !p) return 0;
    return MsgBool1Id(fm, "fileExistsAtPath:", p) ? 1 : 0;
}

static void RemoveFile(const char *path) {
    id fm = FileManager();
    id p = MakeNSString(path);
    if (!fm || !p) return;
    if (MsgBool1Id(fm, "fileExistsAtPath:", p)) {
        MsgBool2IdErr(fm, "removeItemAtPath:error:", p, NULLPTR);
    }
}

static void SetJobError(Job *job, const char *msg) {
    if (!job) return;
    if (job->error) { free(job->error); job->error = NULLPTR; }
    job->error = DupString(msg ? msg : "unknown error");
    job->status = JOB_FAILED;
}

static const char *NSErrorText(id error) {
    if (!error) return "unknown error";
    id desc = MsgId0(error, "localizedDescription");
    if (!desc) return "unknown error";
    const char *s = MsgCStr0(desc, "UTF8String");
    return s ? s : "unknown error";
}

/* ---------- progress + finish callback ---------- */
static void SetProgress(Job *job, int64_t downloadedBytes) {
    if (!job || job->totalBytes <= 0 || !gProgressValue) return;

    float progress = (float)((double)downloadedBytes / (double)job->totalBytes);
    if (progress < 0.0f) progress = 0.0f;
    if (progress > 1.0f) progress = 1.0f;
    int percent = (int)(progress * 100.0f);

    job->progress = progress;
    if (percent == job->lastPercent) return;
    job->lastPercent = percent;

    void *bar = *(void **)((uintptr_t)job->dialog + 0x48);
    if (!bar) return;

    gProgressValue(bar, (float)percent, NULLPTR);

    if (gIl2CppStringNew && gProgressTitle) {
        char title[32];
        snprintf(title, sizeof(title), "%d%%", percent);
        void *il2cppTitle = gIl2CppStringNew(title);
        if (il2cppTitle) gProgressTitle(bar, il2cppTitle, NULLPTR);
    }
}

static void InvokeFinishedCB(void *dialog) {
    if (!dialog) return;
    void *cb = *(void **)((uintptr_t)dialog + 0x50);
    if (!cb) return;

    void *invokeImpl = *(void **)((uintptr_t)cb + 0x18);
    void *method = *(void **)((uintptr_t)cb + 0x28);
    void *target = *(void **)((uintptr_t)cb + 0x40);
    if (!invokeImpl) return;

    ((void (*)(void *, void *))invokeImpl)(target, method);
}

static void CloseDialog(void *dialog) {
    if (gClose && dialog) gClose(dialog, NULLPTR);
}

/* ---------- download engine ---------- */
static void DownloadNext(Job *job);

static void DidWriteData(id self, SEL _cmd, id nsSession, id task,
                         int64_t bytesWritten, int64_t totalBytesWritten,
                         int64_t totalBytesExpectedToWrite) {
    (void)self; (void)_cmd; (void)nsSession; (void)bytesWritten; (void)totalBytesExpectedToWrite;
    unsigned long taskId = MsgUL0(task, "taskIdentifier");
    TaskContext *ctx = FindTaskContext(taskId);
    if (!ctx || !ctx->job) return;
    SetProgress(ctx->job, ctx->job->completedBytes + totalBytesWritten);
}

static void DidFinishDownloading(id self, SEL _cmd, id nsSession, id task, id location) {
    (void)self; (void)_cmd; (void)nsSession;
    unsigned long taskId = MsgUL0(task, "taskIdentifier");
    TaskContext *ctx = FindTaskContext(taskId);
    if (!ctx || !ctx->job || !ctx->file) return;

    Job *job = ctx->job;
    const ModelFile *file = ctx->file;
    char dstPath[PATH_CAP];
    if (snprintf(dstPath, sizeof(dstPath), "%s/%s", job->dir, file->name) <= 0) {
        SetJobError(job, "path build failed");
        return;
    }

    id dstPathString = MakeNSString(dstPath);
    id urlClass = ClassObj("NSURL");
    id dstURL = (urlClass && dstPathString) ? MsgId1Id(urlClass, "fileURLWithPath:", dstPathString) : NULLPTR;
    id fm = FileManager();
    if (!fm || !dstURL || !location) {
        SetJobError(job, "Foundation URL setup failed");
        return;
    }

    RemoveFile(dstPath);

    id error = NULLPTR;
    ObjCBool ok = MsgBool2IdIdErr(fm, "moveItemAtURL:toURL:error:", location, dstURL, &error);
    if (!ok) {
        SetJobError(job, NSErrorText(error));
        return;
    }

    job->completedBytes += file->size;
    job->index++;
    SetProgress(job, job->completedBytes);
    RemoveTaskContext(taskId);

    if (job->currentTask) {
        ReleaseObj(job->currentTask);
        job->currentTask = NULLPTR;
    }

    DownloadNext(job);
}

static void DidCompleteWithError(id self, SEL _cmd, id nsSession, id task, id error) {
    (void)self; (void)_cmd; (void)nsSession;
    if (!error) return;

    unsigned long taskId = MsgUL0(task, "taskIdentifier");
    TaskContext *ctx = FindTaskContext(taskId);
    if (!ctx || !ctx->job) return;

    Job *job = ctx->job;
    SetJobError(job, NSErrorText(error));
    RemoveTaskContext(taskId);
    if (job->currentTask) {
        ReleaseObj(job->currentTask);
        job->currentTask = NULLPTR;
    }
}

static Class RegisterDownloadDelegateClass(void) {
    char className[128];
    snprintf(className, sizeof(className), "NVGitHubDownloadDelegate_%d", getpid());

    Class existing = objc_getClass(className);
    if (existing) return existing;

    Class nsObject = objc_getClass("NSObject");
    if (!nsObject) return NULLPTR;

    Class cls = objc_allocateClassPair(nsObject, className, 0);
    if (!cls) return NULLPTR;

    class_addMethod(cls,
        S("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:"),
        (void *)DidWriteData, "v@:@@qqq");
    class_addMethod(cls,
        S("URLSession:downloadTask:didFinishDownloadingToURL:"),
        (void *)DidFinishDownloading, "v@:@@@");
    class_addMethod(cls,
        S("URLSession:task:didCompleteWithError:"),
        (void *)DidCompleteWithError, "v@:@@@");

    Protocol *p = objc_getProtocol("NSURLSessionDownloadDelegate");
    if (p) class_addProtocol(cls, p);

    objc_registerClassPair(cls);
    return cls;
}

static int SetupSession(void) {
    if (gSession) return 1;

    Class delegateClass = RegisterDownloadDelegateClass();
    if (!delegateClass) return 0;

    id delegateAlloc = MsgId0((id)delegateClass, "alloc");
    gDelegate = delegateAlloc ? MsgId0(delegateAlloc, "init") : NULLPTR;
    if (!gDelegate) return 0;

    id cfgClass = ClassObj("NSURLSessionConfiguration");
    id sessionClass = ClassObj("NSURLSession");
    id queueClass = ClassObj("NSOperationQueue");
    if (!cfgClass || !sessionClass || !queueClass) return 0;

    id cfg = MsgId0(cfgClass, "defaultSessionConfiguration");
    id queue = MsgId0(queueClass, "mainQueue");
    if (!cfg || !queue) return 0;

    gSession = MsgId3Id(sessionClass,
                        "sessionWithConfiguration:delegate:delegateQueue:",
                        cfg, gDelegate, queue);
    if (!gSession) return 0;
    RetainObj(gSession);
    return 1;
}

static void DownloadNext(Job *job) {
    if (!job || job->status == JOB_FAILED) return;

    if (job->index >= job->fileCount) {
        SetProgress(job, job->totalBytes);
        job->status = JOB_DONE;
        return;
    }

    const ModelFile *file = &job->files[job->index];
    char dstPath[PATH_CAP];
    snprintf(dstPath, sizeof(dstPath), "%s/%s", job->dir, file->name);

    if (FileExists(dstPath)) {
        job->completedBytes += file->size;
        job->index++;
        SetProgress(job, job->completedBytes);
        DownloadNext(job);
        return;
    }

    char urlBuffer[URL_CAP];
    snprintf(urlBuffer, sizeof(urlBuffer), "%s%s", GH_BASE, file->name);
    id urlString = MakeNSString(urlBuffer);
    id urlClass = ClassObj("NSURL");
    id url = (urlClass && urlString) ? MsgId1Id(urlClass, "URLWithString:", urlString) : NULLPTR;
    if (!url || !gSession) {
        SetJobError(job, "download URL/session unavailable");
        return;
    }

    id task = MsgId1Id(gSession, "downloadTaskWithURL:", url);
    if (!task) {
        SetJobError(job, "downloadTaskWithURL failed");
        return;
    }

    unsigned long taskId = MsgUL0(task, "taskIdentifier");
    AddTaskContext(taskId, job, file);

    if (job->currentTask) ReleaseObj(job->currentTask);
    job->currentTask = task;
    RetainObj(task);
    MsgVoid0(task, "resume");
}

static Job *StartJob(void *sm, void *dialog, const char *resource) {
    if (FindJob(sm)) return FindJob(sm);

    Job *job = (Job *)malloc(sizeof(Job));
    if (!job) return NULLPTR;

    /* Explicit init to avoid libc memset dependency. */
    job->sm = sm;
    job->dialog = dialog;
    job->resource[0] = '\0';
    job->dir[0] = '\0';
    job->files = NULLPTR;
    job->fileCount = 0;
    job->index = 0;
    job->totalBytes = 0;
    job->completedBytes = 0;
    job->progress = 0.0f;
    job->lastPercent = -1;
    job->currentTask = NULLPTR;
    job->status = JOB_DOWNLOADING;
    job->error = NULLPTR;
    job->finalized = 0;
    job->next = NULLPTR;
    CopyString(job->resource, sizeof(job->resource), resource);

    const char *familyDir = NULLPTR;

    /* Exact MODEL_MAP lookup, matching 2.js semantics. */
    if (resource && strcmp(resource, "_depthgenerator") == 0) {
        familyDir = "DepthAnything";
        job->files = kDepthFiles;
        job->fileCount = (int)(sizeof(kDepthFiles) / sizeof(kDepthFiles[0]));
    } else if (resource && strcmp(resource, "_sam2") == 0) {
        familyDir = "SAM2";
        job->files = kSam2Files;
        job->fileCount = (int)(sizeof(kSam2Files) / sizeof(kSam2Files[0]));
    } else if (resource && ContainsHDCaseInsensitive(resource)) {
        familyDir = "";
        SetJobError(job, "unsupported HD");
        AddJob(job);
        return job;
    } else {
        familyDir = "FaceDIY";
        job->files = kFaceFiles;
        job->fileCount = (int)(sizeof(kFaceFiles) / sizeof(kFaceFiles[0]));
    }

    char docs[PATH_CAP];
    if (!GetDocumentsPath(docs, sizeof(docs))) {
        SetJobError(job, "Documents path unavailable");
        AddJob(job);
        return job;
    }

    snprintf(job->dir, sizeof(job->dir), "%s/AppAssets/%s", docs, familyDir);
    MkdirPath(job->dir);

    for (int i = 0; i < job->fileCount; i++) job->totalBytes += job->files[i].size;

    AddJob(job);
    SetProgress(job, 0);
    DownloadNext(job);
    return job;
}

/* ---------- hooked coroutine ---------- */
static int HookedMoveNext(void *sm, void *methodInfo) {
    if (!gEnabled && gOriginalMoveNext) return gOriginalMoveNext(sm, methodInfo);
    if (!sm) return 0;

    void *dialog = *(void **)((uintptr_t)sm + 0x20);
    if (!dialog) return 0;

    void *resourcePtr = *(void **)((uintptr_t)dialog + 0x60);
    char resource[RESOURCE_CAP];
    const char *resourceText = NULLPTR;
    if (ReadIl2CppStringAscii(resourcePtr, resource, sizeof(resource))) resourceText = resource;

    Job *job = FindJob(sm);
    if (!job) {
        job = StartJob(sm, dialog, resourceText);
        return job ? 1 : 0;
    }

    if (job->status == JOB_DOWNLOADING) return 1;

    if (job->status == JOB_FAILED) {
        if (!job->finalized) {
            job->finalized = 1;
            CloseDialog(dialog);
        }
        RemoveJob(sm);
        return 0;
    }

    if (job->status == JOB_DONE) {
        if (!job->finalized) {
            job->finalized = 1;
            SetProgress(job, job->totalBytes);
            InvokeFinishedCB(dialog);
            CloseDialog(dialog);
        }
        RemoveJob(sm);
        return 0;
    }

    return 1;
}

/* ---------- install ---------- */
static int InstallForImage(const struct mach_header *mh, const char *imagePath) {
    if (gHookInstalled || !mh || !imagePath) return gHookInstalled;
    const char *name = LastPathComponent(imagePath);
    if (!name || strcmp(name, MODULE_NAME) != 0) return 0;

    if (!SetupSession()) {
        printf("[-] NodeVideoGitHubDownloader: NSURLSession setup failed\n");
        return 0;
    }

    uintptr_t base = (uintptr_t)mh;
    void *moveNext = (void *)(base + RVA_MOVE_NEXT);
    gClose = (CloseFn)(base + RVA_CLOSE);
    gProgressTitle = (ProgressTitleFn)(base + RVA_PROGRESS_SET_TITLE);
    gProgressValue = (ProgressValueFn)(base + RVA_PROGRESS_SET_VALUE);

    /* JS uses Module.findGlobalExportByName(): RTLD_DEFAULT is the native equivalent. */
    gIl2CppStringNew = (Il2CppStringNewFn)dlsym(RTLD_DEFAULT, "il2cpp_string_new");
    gMSHookFunction = (MSHookFunctionFn)dlsym(RTLD_DEFAULT, "MSHookFunction");
    gDobbyHook = (DobbyHookFn)dlsym(RTLD_DEFAULT, "DobbyHook");

    if (gMSHookFunction) {
        gMSHookFunction(moveNext, (void *)HookedMoveNext, (void **)&gOriginalMoveNext);
    } else if (gDobbyHook) {
        int rc = gDobbyHook(moveNext, (void *)HookedMoveNext, (void **)&gOriginalMoveNext);
        if (rc != 0) {
            printf("[-] NodeVideoGitHubDownloader: DobbyHook failed rc=%d\n", rc);
            return 0;
        }
    } else {
        printf("[-] NodeVideoGitHubDownloader: no MSHookFunction/DobbyHook backend\n");
        return 0;
    }

    if (!gOriginalMoveNext) {
        printf("[-] NodeVideoGitHubDownloader: hook backend returned no trampoline\n");
        return 0;
    }

    gHookInstalled = 1;

    printf("[+] NodeVideoGitHubDownloader installed: base=%p MoveNext=%p\n", (void *)base, moveNext);
    printf("[+] il2cpp_string_new=%p\n", (void *)gIl2CppStringNew);
    return 1;
}

static void DeferredInstall(void *context) {
    const struct mach_header *mh = (const struct mach_header *)context;
    gInstallScheduled = 0;
    if (!mh || gHookInstalled) return;

    Dl_info info;
    info.dli_fname = NULLPTR;
    info.dli_fbase = NULLPTR;
    info.dli_sname = NULLPTR;
    info.dli_saddr = NULLPTR;
    if (dladdr((const void *)mh, &info) == 0 || !info.dli_fname) return;
    InstallForImage(mh, info.dli_fname);
}

static void ImageAdded(const struct mach_header *mh, intptr_t vmaddr_slide) {
    (void)vmaddr_slide;
    if (!mh || gHookInstalled || gInstallScheduled) return;

    Dl_info info;
    info.dli_fname = NULLPTR;
    info.dli_fbase = NULLPTR;
    info.dli_sname = NULLPTR;
    info.dli_saddr = NULLPTR;
    if (dladdr((const void *)mh, &info) == 0 || !info.dli_fname) return;

    const char *name = LastPathComponent(info.dli_fname);
    if (!name || strcmp(name, MODULE_NAME) != 0) return;

    /* Keep dyld callback minimal; Foundation/session setup runs on main queue. */
    gInstallScheduled = 1;
    dispatch_async_f((dispatch_queue_t)&_dispatch_main_q, (void *)mh, DeferredInstall);
}

__attribute__((constructor))
static void NVGitHubDownloaderInitialize(void) {
    _dyld_register_func_for_add_image(ImageAdded);
}

/* Optional reversible runtime control. Enabled state matches 2.js by default. */
__attribute__((visibility("default")))
void NVGitHubDownloaderSetEnabled(int enabled) {
    if (!enabled && gJobs) return;
    gEnabled = enabled ? 1 : 0;
}

__attribute__((visibility("default")))
int NVGitHubDownloaderIsInstalled(void) {
    return gHookInstalled;
}

__attribute__((visibility("default")))
const char *NVGitHubDownloaderBuildInfo(void) {
    return "2.js native port; UnityFramework RVAs 2E13604/2E12C94/5B39F30/5B3A674";
}