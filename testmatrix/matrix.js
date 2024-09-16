window.addEventListener('load', (event) => {
    document.querySelectorAll('.test_results td').forEach((td) => {
        var buildn = td.getAttribute('build');
        var build = build_info[buildn];
        console.log(build);
        if (build) {
            // Put build name in tooltip
            td.setAttribute('title', `#${buildn} ${build.name}`);

            var test_subsec = td.getAttribute('test');
            if (test_subsec) {
                // Link to test run output
                var a = document.createElement('a');
                var url = `${build.name}/${build.basename}_`;
                if (td.classList.contains('f')) {
                    url += 'Brief';
                } else {
                    url += 'Full';
                }
                a.href = `${url}.html#subsection_${test_subsec}`;
                // a.textContent = td.textContent;
                td.replaceChildren(a);
            }
        }
    });

    if (props.source_link) {
        document.querySelectorAll('.test_results td.test_name').forEach((td) => {
            var a = document.createElement('a');
            var parts = td.textContent.split(" ");
            a.href = props.source_link + parts[0];
            a.textContent = parts[0];

            var span = document.createElement('span');
            span.textContent = ' ' + parts.slice(1).join(' ');

            td.replaceChildren(a, span)
        });
    }
});
