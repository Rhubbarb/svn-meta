@echo off

copy _hook_template_.bat.tmpl start-commit.bat
copy _hook_template_.bat.tmpl pre-commit.bat
copy _hook_template_.bat.tmpl post-commit.bat

copy _hook_template_.bat.tmpl pre-revprop-change.bat
copy _hook_template_.bat.tmpl post-revprop-change.bat
