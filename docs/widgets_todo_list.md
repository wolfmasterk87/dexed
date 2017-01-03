---
title: Widgets - Todo list
---

### Todo list

#### Description

The _todo list_ widget displays the _todo comments_ located in the source files.

![](img/todo_list.png)

When no source file is opened but a project is, the widget displays the comments of the whole project. 
When a source file has the focus and if it is not part of the project then the widget only displays the items located in this file.
Otherwise if a file has the focus and if it's part of the project then the whole project *todos* are displayed.

It's possible to jump to a particular item in its file with a double click.
The items cannot be edited in the widget.

- ![](https://raw.githubusercontent.com/BBasile/Coedit/master/icons/arrow/arrow_update.png): Refreshes the list manually .
- ![](https://raw.githubusercontent.com/BBasile/Coedit/master/icons/arrow/arrow_pen.png): Jump to the item declaration.

#### Format

The _todo comments_ must follow this format:
> TODO|FIXME|NOTE -cCategory -aAssignee -pPriority -sStatus : what

The fields (-a -c -p -s) are optional but the _what_ is mandatory.

For example

```D
// TODO: something.
// TODO-cfixes: something to fix.
// TODO-cfixes-aMrFreeze: something that MrFreezae has to fix.
// NOTE: a reminder.
```

are valid _todos_.

#### Options

![](img/options_todo_list.png)

- **autoRefresh**: Automatically refreshes the list when a document or a project is activated and following the rules described upper.
- **columns**: Selects which columns are visible. Despite of the settings a column is only displayed when at least one item uses the matching field.
- **singleClickSelect**: Defines how the mouse is used to go to the item declaration.