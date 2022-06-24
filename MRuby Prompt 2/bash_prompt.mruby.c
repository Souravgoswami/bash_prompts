#pragma GCC optimize("Os")

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <dirent.h>
#include <unistd.h>
#include <linux/limits.h>
#include <pwd.h>
#include <sys/types.h>
#include <time.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <pwd.h>

#include <mruby.h>
#include <mruby/compile.h>

#include "bash_profile.rb.h"

#define SUCCESS 0
#define FAILURE 1

#define TIME_FORMAT "%H:%M:%S"
#define TIME_RETURN_SIZE 9

void get_cwd(char *cwd) {

}

mrb_value get_hostname(mrb_state *s, mrb_value self) {
	int h_max = sysconf(_SC_HOST_NAME_MAX) + 1 ;
	char hostname[h_max] ;
	char status = gethostname(hostname, h_max) ;

	return mrb_str_new_cstr(s, (status < 0) ? "" : hostname) ;
}

mrb_value get_logname(mrb_state *s, mrb_value self) {
	struct passwd *p = getpwuid(getuid()) ;

	if (!p) return mrb_nil_value() ;
	return mrb_str_new_cstr(s, p->pw_name) ;
}

mrb_value get_current_time(mrb_state *s, mrb_value self) {
	time_t t ;
	struct tm *tp ;
	time(&t) ;

	if (!t) {
		return mrb_nil_value() ;
	}

	size_t size = TIME_RETURN_SIZE ;
	char formatted_time[size] ;

	tp = localtime(&t) ;
	strftime(formatted_time, size, TIME_FORMAT, tp) ;

	return mrb_str_new_cstr(s, formatted_time) ;

}

mrb_value get_pwd(mrb_state *s, mrb_value self) {
	char cwd[PATH_MAX] ;

	if (getcwd(cwd, sizeof(cwd))) {
		struct passwd *pw = getpwuid(getuid()) ;
		char *homedir = pw->pw_dir ;
		const unsigned long homedir_len = strlen(homedir) ;
		const unsigned long cwd_len = strlen(cwd) ;

		// If string starts with user home directory
		if (strncmp(homedir, cwd, homedir_len) == 0) {
			char *pretty_home = "~" ;
			char *tmp = malloc(cwd_len + strlen(pretty_home) + 1) ;
			memmove(cwd, cwd + homedir_len, cwd_len + 1) ;
			sprintf(tmp, "%s%s", pretty_home, cwd) ;
			strcpy(cwd, tmp) ;
			free(tmp) ;
		}

		return mrb_str_new_cstr(s, cwd) ;
	} else {
		return mrb_nil_value() ;
	}
}

mrb_value count_files(mrb_state *s, mrb_value self) {
	DIR *dirp ;
	struct dirent *entry ;
	unsigned long count = 0 ;
	char *name ;

	char cwd[PATH_MAX] ;
	if (!getcwd(cwd, sizeof(cwd))) return mrb_nil_value() ;

	dirp = opendir(cwd) ;

	while ((entry = readdir(dirp))) {
		name = entry->d_name ;

		if (
			name[0] == '.' &&
			(name[1] == '\0' || (name[1] == '.' && name[2] == '\0'))
		) continue;

		++count ;
	}

	return mrb_fixnum_value(count) ;
}

int main() {
	mrb_state *mrb = mrb_open() ;

	struct RClass *d = mrb_define_module(mrb, "CPrompt") ;
	mrb_define_class_method(mrb, d, "get_hostname", get_hostname, MRB_ARGS_NONE()) ;
	mrb_define_class_method(mrb, d, "get_logname", get_logname, MRB_ARGS_NONE()) ;
	mrb_define_class_method(mrb, d, "get_current_time", get_current_time, MRB_ARGS_NONE()) ;
	mrb_define_class_method(mrb, d, "get_pwd", get_pwd, MRB_ARGS_NONE()) ;
	mrb_define_class_method(mrb, d, "count_files", count_files, MRB_ARGS_NONE()) ;

	mrb_load_string(mrb, code()) ;
	mrb_close(mrb) ;
}
