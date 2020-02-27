const defaultOutNum as integer = 82

declare sub debug_console(message as string, outNum as integer = defaultOutNum)

sub debug_console(message as string, outNum as integer = defaultOutNum)
    open cons for output as #outNum
        print #outNum, message
    close #outNum
end sub
