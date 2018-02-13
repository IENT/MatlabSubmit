MatlabSubmit
================
This tool helps you to run MATLAB jobs on a computer cluster and analyse results.  
In order to get a quick start, just run example.m. For this you need to adjust some paths, as we do not know how your architecture looks like (you should modify conf.tmp_dir).
If you have further questions or want to report bugs, do not hesitate to open an issue.

Supported cluster platforms
-------------------
- Sun Grid Engine   
- IBM LSF 

Installation
----------

- Add the +queue-folder to your MATLAB path.
- Create a temporary directory.
- Run example.m


Help
-----

To get an overview of the functionality, type

    help +queue

In order to get an insight into the implementation, type

    help queue.internal
    help queue.results

A help should be available for each function. Using 'doc queue.foo' works as well.
