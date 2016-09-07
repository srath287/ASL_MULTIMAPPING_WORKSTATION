function [mapUpdate, robPoseMapFrame, laserEndPntsMapFrame] = inv_sensor_model(map, scan, robPose, gridSize, offset, probPrior, probOcc, probFree,maxRange)
% Compute the log odds values that should be added to the map based on the inverse sensor model
% of a laser range finder.

% map is the matrix containing the occupancy values (IN LOG ODDS) of each cell in the map.
% scan is a laser scan made at this time step. Contains the range readings of each laser beam.
% robPose is the robot pose in the world coordinate frame.
% gridSize is the size of each grid in meters.
% offset = [offsetX; offsetY] is the offset that needs to be subtracted from a point
% when converting to map coordinates.
% probOcc is the probability that a cell is occupied by an obstacle given that a
% laser beam endpoint hit that cell.
% probFree is the probability that a cell is occupied given that a laser beam passed through it.

% mapUpdate is a matrix of the same size as map. It has the log odds values that need to be added for the cells
% affected by the current laser scan.
% robPoseMapFrame is the pose of the robot in the map coordinate frame.
% laserEndPntsMapFrame are map coordinates of the endpoints of each laser beam (also used for visualization purposes).

% TODO: Initialize mapUpdate.
    l0=prob_to_log_odds(probPrior);
    smap=size(map);
    mapUpdate=l0*ones(smap);

% Robot pose as a homogeneous transformation matrix.
    robTrans = v2t(robPose);

% TODO: compute robPoseMapFrame. Use your world_to_map_coordinates implementation.
    robPoseMapFrame=world_to_map_coordinates(robPose(1:2),gridSize,offset);

% Compute the Cartesian coordinates of the laser beam endpoints.
% Set the third argument to 'true' to use only half the beams for speeding up the algorithm when debugging.
    laserEndPnts = robotlaser_as_cartesian(scan, maxRange, false);

% Compute the endpoints of the laser beams in the world coordinates frame.
    laserEndPnts = robTrans*laserEndPnts;
% TODO: compute laserEndPntsMapFrame from laserEndPnts. Use your world_to_map_coordinates implementation.
    laserEndPntsMapFrame=world_to_map_coordinates(laserEndPnts(1:2,:),gridSize,offset);

%     figure(1)
%         plot(robPoseMapFrame(1),robPoseMapFrame(2),'rx')
%         hold on;
%         plot(laserEndPntsMapFrame(1,:),laserEndPntsMapFrame(2,:),'b.')
%         hold off

    
% Iterate over each laser beam and compute freeCells.
% Use the bresenham method available to you in tools for computing the X and Y
% coordinates of the points that lie on a line.
% Example use for a line between points p1 and p2:
% [X,Y] = bresenham([p1_x, p1_y; p2_x, p2_y]);
% You only need the X and Y outputs of this function.

    therewasanerror=false;
    loccp=prob_to_log_odds(probOcc);
    lfree=prob_to_log_odds(probFree);
    freeCells=[];
    occpCells=[];
    %MODIFIED=[];
    for sc=1:columns(laserEndPntsMapFrame)
        %TODO: compute the XY map coordinates of the free cells along the laser beam ending in laserEndPntsMapFrame(:,sc)
        try
        [X,Y] = bresenham([robPoseMapFrame(1:2)';laserEndPntsMapFrame(1,sc) laserEndPntsMapFrame(2,sc)]);
        catch hell
            %I keep getting a bitshift error caused by error going negative.  But in the end, I seem to get the correct result.
            fprintf('There was an error with error.\n');
            continue;
        end 
        %TODO: add them to freeCells and occpCells
        % freeCells are the map coordinates of the cells through which the laser beams pass.
        % occpCells are the map coordinates of the cells through which the laser beams end.
        try
        freeCells=sub2ind(smap,X,Y);
        occpCells=sub2ind(smap,laserEndPntsMapFrame(1,sc),laserEndPntsMapFrame(2,sc));
        %MODIFIED=[MODIFIED freeCells occpCells];%Does not result in desired effect.
        catch hell
            therewasanerror=true;
            %fprintf('Why am I here?\n');
        end
        
        %TODO: update the log odds values in mapUpdate for each free cell according to probFree.
        mapUpdate(freeCells)=lfree+mapUpdate(freeCells);
        
        %TODO: update the log odds values in mapUpdate for each laser endpoint according to probOcc.
        mapUpdate(occpCells)=loccp+mapUpdate(occpCells);
    end

    if (therewasanerror)
        %fprintf('Outside of bounds.\n');
    end
end
