updateResults();

oIm = getImageID();
oTitle = getTitle();


if(nResults > 1){
	if(nResults >256)
		exit("This method only supports 256 different clusters, but in practice works best with a handful");
}else if(roiManager("Count") > 1){
	run("Measure ROIs");
	if(nResults >256)
		exit("This method only supports 256 different clusters, but in practice works best with a handful");

} else exit("There are no results or ROIs");

updateResults();
run("Naive Bayes Classify");
