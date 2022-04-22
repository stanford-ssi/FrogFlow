function savecurrfig(figname)
    f = gcf;
    p = mfilename('fullpath');
    [currloc,~,~] = fileparts(p);
    exportgraphics(f,fullfile(currloc, '../outputs',[figname '.png']),'Resolution',600,'BackgroundColor','none'); 
end