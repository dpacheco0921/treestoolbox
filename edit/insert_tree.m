% INSERT_TREE   Insert a number of points into a tree.
% (trees package)
%
% [tree, ind] = insert_tree (intree, swc,  options)
% -------------------------------------------------
%
% Inserts a set of points defined by a matrix pars.swc in SWC order
% ([inode R X Y Z D idpar] BUT NOTE that diameter values are given and NOT
% radius!) into a tree intree. This function alters the original
% morphology! Trifurcations can occur but are not identified to keep speed
% high.
%
% Input
% -----
% - intree   ::integer:index of tree in trees or structured tree
% - pars.swc      ::matrix: points in pars.swc-like format [inode R X Y Z D idpar]
%     NOTE that diameter values and NOT radius values are used.
%     inode values are not considered. If scalar, indicates number of
%     random points within tree bounding box.
%     {DEFAULT: nothing!! (this used to be: add random point)}
% - options  ::string:
%     '-s'   : show
%     '-e'   : echo added nodes
%     '-d'   : delete obsolete regions (NOTE! BUG, see code)
%     {DEFAULT: '-e'}
%
% Output
% ------
% if no output is declared the tree is changed in trees
% - tree     :: structured output tree
% - ind      :: indices of added nodes
%
% Example
% -------
% insert_tree (sample_tree, [...
%    1 1 200 -140 0 4 3; ...
%    2 1 200  -60 0 4 3], '-s -e');
%
% See also insertp_tree
% Uses ver_tree dA
%
% Added node index output by Marcel Beining 2017
%
% the TREES toolbox: edit, generate, visualise and analyse neuronal trees
% Copyright (C) 2009 - 2023  Hermann Cuntz

function [tree, ind] = insert_tree (intree, varargin)

ver_tree     (intree); % verify that input is a tree structure
tree         = intree;

%=============================== Parsing inputs ===============================%
p = inputParser;
p.addParameter('swc', [])
p.addParameter('e', true, @isBinary)
p.addParameter('d', false, @isBinary)
p.addParameter('s', false, @isBinary)
pars = parseArgs(p, varargin, {'swc'}, {'e', 'd', 's'});
%==============================================================================%

N            = size (tree.dA, 1);
N2           = size (pars.swc, 1);

if ~isempty  (pars.swc)
    tree.dA      = [[tree.dA, ...
        (sparse  (N,  N2))]; ...
        (sparse  (N2, N + N2))];
    ind          = (N + 1 : N + N2)';
    tree.dA (sub2ind ( ...
        [(N + N2), (N + N2)], ...
        ind,   pars.swc (:, 7))) = 1;
    
    if isfield   (tree, 'X')
        tree.X   = [tree.X; (pars.swc (:, 3))];
    end
    if isfield   (tree, 'Y')
        tree.Y   = [tree.Y; (pars.swc (:, 4))];
    end
    if isfield   (tree, 'Z')
        tree.Z   = [tree.Z; (pars.swc (:, 5))];
    end
    if isfield   (tree, 'D')
        tree.D   = [tree.D; (pars.swc (:, 6))];
    end
    if isfield   (tree, 'jpoints') 
        tree.jpoints = [tree.jpoints; (zeros (N2, 1))];
    end
    if isfield       (tree, 'R')
        % eliminate obsolete regions (only if everything is correct)
        if pars.d
            if isfield   (tree, 'rnames')
                % my god! Handling regions is not easy!!!!!!
                % AND IS WRONG!!!!! IF FIRST REGION DOES NOT EXIST, THERE IS A
                % SHIFT OF REGION NAMES THAT ARE DELETED..!!!!
                [i1, ~, i3]  = unique    ([tree.R; (pars.swc (:, 2))]);
                [~, i5, i6]  = intersect (unique (tree.R), i1);
                rnames       = cell (1, 1);
                for counter  = 1 : length (i1)
                    rnames {counter} = num2str (i1 (counter));
                end
                rnames (i6)  = tree.rnames (i5);
                tree.rnames  = rnames;
                tree.R       = i3;
            else
                [~, ~, i3]   = unique ([tree.R; (pars.swc (:, 2))]);
                tree.R       = i3;
            end
        else
            tree.R           = [tree.R; (pars.swc (:, 2))];
        end
    end
end

if pars.s   % show option
    clf;
    hold         on;
    if ~isempty (pars.swc)
        pointer_tree ( [ ...
            (pars.swc (:, 3)), ...
            (pars.swc (:, 4)), ...
            (pars.swc (:, 5))], (1 : N2)');
    end
    xplore_tree  (tree);
    title        ('insert nodes');
    xlabel       ('x [\mum]');
    ylabel       ('y [\mum]');
    zlabel       ('z [\mum]');
    view         (2);
    grid         on;
    axis         image;
end

if pars.e   % echo changes
    warning      ('TREES:notetreechange', ...
        ['added ' (num2str (size (pars.swc, 1))) ' node(s)']);
end

