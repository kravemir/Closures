
all: llvm-trampoline

llvm-trampoline: main.ll
	clang main.ll -o llvm-trampoline

run: all
	@echo running llvm-trampoline:
	@./llvm-trampoline
