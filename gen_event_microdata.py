#!/bin/python2.7
# Generate Event Microdata of the first two months. Update index.html accordingly.
import re
import json
import datetime

event_file = "./data/json/events.json"
index_file = "./static/index.html"
event = """<div itemscope itemtype="http://data-vocabulary.org/Event">
    <a href="http://chorknaben-biberach.de/#!/kalender" itemprop="url">
        <span itemprop="summary" content="{0}"></span>
    </a>
    <time itemprop="startDate" datetime="{1}"></time>
    <span itemprop="location" content="{2}"></span>
    <span itemprop="name" content="{3}"></span>
</div>
"""

def main(ev):
	current_datetime = datetime.datetime.now()

	html_events = []
	for i in ev["events"]:
		try:
			day_month_year = i["date"].split(".")
			hour_minute = i["time"].split(".")

			day_month_year = map(lambda x: int(x), day_month_year)
			hour_minute = map(lambda x: int(x), hour_minute)

			if int(day_month_year[1]) < current_datetime.month +2 and int(day_month_year[1]) >= current_datetime.month:
				# Only Events happening in the next month are interesting for google
				dt =  datetime.datetime(day_month_year[2], day_month_year[1], day_month_year[0], hour_minute[0], hour_minute[1])
				html_events.append(event.format(i["title"], dt.isoformat(), i["location"], i["title"]))
		except ValueError:
			pass

	string = "\n".join(html_events)

	indexfile = open(index_file, 'r')
	indexcnt = indexfile.readlines()
	indexfile.close()

	i0 = indexcnt.index("<!-- ev -->\n")
	i1 = indexcnt[i0+1:len(indexcnt)-1].index("<!-- ev -->\n")
	for i in range(0, i1):
		del indexcnt[i0+1]
	indexcnt.insert(i0+1,string)

	final_file =  "".join(indexcnt)
	indexfile = open(index_file, 'w+')
	indexfile.write(final_file)
	indexfile.close()
	print "Insertion suceeded"




if __name__ == '__main__':
	with open(event_file, "r") as f:
		ev = json.load(f)
		main(ev)


