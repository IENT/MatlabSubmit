% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

edit('example.m');
disp('Welcome to MATLAB SUBMIT EXAMPLE!')
pause();

%-------------------------------------------------------------------------%
%------------------------MATLAB SUBMIT EXAMPLE----------------------------%
%-------------------------------------------------------------------------%

% MATLAB SUBMIT is a tool to run MATLAB functions on the IENT cluster. In 
% this example the fundamental functionality of MATLAB SUBMIT is demonstrated. 

% To make it interesting we are going to create some beautiful images of 
% fractals (if you don't know what fractals are you might want to take a 
% quick look at 'http://en.wikipedia.org/wiki/Fractal') 

% First we need a function that calculates the fractals for us. Luckily 
% there is one in this very folder. Please open 'example_function.m' and 
% skim through it a bit...
    
% As you see we need one input for the function called 'p'. This is 
% the so called parameter struct. It contains parameters needed for the
% calculation. We want to see plenty of fractals, therefore let's start to 
% create a parameter struct on our own:

%% CREATION OF PARAMETER STRUCT

    % In the first line of the example function we will need coefficients for 
    % the polynome we want to create our fractals from. We would like to try
    % many different polynomes and look which one creates the prettiest images.
    
    % Let's define a set of possible values for each coefficient:
    
    p.coeff0 = {-1, 0.5i, 1};
    p.coeff1 = {0, 0.5};
    p.coeff2 = {-0.5, 0, 0.5};
    p.coeff3 = {-1, 0};    
    
    % Additionally we will need a field called 'number_of_iterations' in 
    % the next line. Let's see if 10 iterations are enough:
    
    p.number_of_iterations = {10};
    
    % We have defined 5 parameters with 3, 2, 3, 2 and 1 values. There are 
    % 3*2*3*2*1 ways to combine parameter values. All of these combinations 
    % will be evaluated when we submit the job to the cluster!
    
    % Right now they would all be computed on a single server. That's bad,
    % we would rather use several servers in parallel. For this purpose
    % there is a special field 'external' in the parameter struct.
    % For example let's do:
    
    p.external = {'coeff3'};
    
    % By this you create a job for each value of 'coeff3' which then can be 
    % submitted to a different server. Then on these servers all combination of 
    % the remaining parameters are carried out. You could also name multiple 
    % variables, like:
    
    p.external = {'coeff2', 'coeff3'};
    
    % Then there is a subjob for each combination of these two parameters.
    
% Alright, the next thing we have to do is pass some information to the 
% cluster software. This is done within a configuration structure:
    
%% CREATION OF CONFIGURATION STRUCT

    % First we have to specify the function we want to evaluate.
    % We do this in form of a function handle. In this case it's our 
    % 'example_function':
    
    conf.fun_handle = @example_function;
    
    % Then we need to define a function loading our favorized config
    % This is dependent on the job system we are using
    % In this example "sun grid engine" is used
    % IBM lsf is also supported
    conf.default_conf = @queue.internal.sge_default_conf;
    
    % Also we want to choose a name for our job:
    
    conf.job_name = 'MATLAB_SUBMIT_example';
    
    % There are many more configuration options but for this example this 
    % should be enough.
    
% There is one last thing we have to do. We will need a temporary directory
% to store some data. Please manually create the directory '/scratch/$USER/tmp'
% (replace '$USER' by your username)! You only need to do this once.

% Ok, we have finished the preparation! Then let's submit our job: 
% (press a key to run the script if you haven't already)

%% JOB SUBMISSION
fprintf('\nJOB SUBMISSION\n');

    queue.submit_job(p, conf);
%     queue.submit_job(p, conf, 1);
    disp('When jobs finished press any key!')
    pause()
    
    % As you see, all we have to do is call the function 'submit_job' in the 
    % '+queue' folder passing our parameter and configuration struct.
    % Please follow the dialog of the program... 
    
% If the submition was successful, let's take a look at 
% 'http://mamsell.ient.rwth-aachen.de:8080/qstat/qstat.cgi'
% Here you can see all jobs currently running on the cluster. Can you spot
% yours? You might have to refresh the page a few times. Please wait until
% the jobs disappear.

%% COLLECT RESULTS
fprintf('\nCOLLECT RESULTS\n');

% As soon as your jobs disappear from the page they seem to have 
% finished. Let's check that by doing:

    results = queue.collect_results(p, conf);

	% Again follow the dialog. If all jobs were complete you now have all
    % your results stored in the 'results.data'.
    
% Now we can finally take a look at the images. For that we use the evaluation
% function of MATLAB SUBMIT. We have to define a properties struct:

    properties.coeff0.disp = 'win'; % create a new window for every value of coeff0
    properties.coeff2.disp = 'ver'; % create a new vertical subplot for every value of coeff1
    properties.coeff1.disp = 'hor'; % create a new horizantal subplot for every value of coeff2
    properties.coeff3.values = -1; % only use the value -1 of coeff3 for this evaluation
    
    % Take a closer look at the documentation for queue.internal.apply_properties
    % to understand all of that...
    
    % Now we can display the fractals by:
    queue.evaluate(results, 'imagesc', properties, 'fractal')
    
    % Already quite beautiful, isn't it?

%% PARAMETER EXTENSION
fprintf('\nPARAMETER EXTENSION\n');

% When you look at the fractals you might expect they would be sharper if 
% we had used more iterations. We can still do that by extending our parameter 
% struct:

    p.number_of_iterations = {10, 50};
    % p.coeffX and p.external are still the same as before

% If we now submit the job the images we just created aren't calculated again.
% Only new combinations of parameters i.e. the ones with more iterations will 
% be evaluated!

    queue.submit_job(p, conf, 1);
    disp('When jobs finished press any key!')
    pause();
    
%% RESTART
fprintf('\nRESTART\n');

% Before we look at the new results let's take a look at another feature of
% MATLAB SUBMIT: If some jobs failed for whatever reason (for example students 
% shutting down computers...) you can restart them while running 
% 'collect_results'. This makes sense because you only need to recalculate 
% missing results instead of restarting everything.

% We will simulate a failed job by just deleting one of the result mat-files.
% (Don't try this at home ;) )

    delete(sprintf('/scratch/%s/queue_results/MATLAB_SUBMIT_example/1.mat', getenv('USER')));
     
% Now there will a corresponding dialog in 'collect_results'. Follow it and 
% restart the missing job. 

    results = queue.collect_results(p, conf);
    disp('When jobs finished press any key!')
    pause();

% After the restart we have to run 'collect_results' again, now everything
% should be complete.

    results = queue.collect_results(p, conf);
    
% See if we get better images:
    
    properties.number_of_iterations.values = 50; % only show the new fractals with greater number of iterations 
    queue.evaluate(results, properties, 'fractal', 'imagesc')
    
    % This looks more like it, right?

    % (Notice that there is an index for 'number_of_iterations' now because
    % we added a second value.)

%% END OF EXAMPLE

% Now you should be ready to actually do some useful things with MATLAB SUBMIT.
% To learn about details of the software type 'help +queue' or 
% 'help queue.internal' to access the documentation.

disp('END OF EXAMPLE')
pause();

%% TIDY UP

% Delete results so example can be run again (if the results of the job still 
% existed you could only do a parameter extension, not a totally new run)
if exist(sprintf('/scratch/%s/queue_results/MATLAB_SUBMIT_example', getenv('USER')),'dir')
    rmdir(sprintf('/scratch/%s/queue_results/MATLAB_SUBMIT_example', getenv('USER')),'s');
end
